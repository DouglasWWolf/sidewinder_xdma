`timescale 1ns / 1ps

//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>
//            This is a full AXI Master that lacks bursting capabilities
//
// This is identical to the axi4_lite_master.v module, except for the addition of the
// 15 extra signals that comprise full AXI4, along with their fixed assignments.
//<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><>

//====================================================================================
//                        ------->  Revision History  <------
//====================================================================================
//
//   Date     Who   Ver  Changes
//====================================================================================
// 10-May-22  DWW  1000  Initial creation
//====================================================================================


module controller#
(
    parameter integer AXI_DATA_WIDTH = 512,
    parameter integer AXI_ADDR_WIDTH = 64
)
(
    input BUTTON,
    output ALARM,


    //=================== From here down is the AXI4 interface =================
    input wire  M_AXI_ACLK,
    input wire  M_AXI_ARESETN,
        
    // "Specify write address"              -- Master --    -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]      M_AXI_AWADDR,   
    output wire                             M_AXI_AWVALID,  
    input  wire                                             M_AXI_AWREADY,
    output wire  [2 : 0]                    M_AXI_AWPROT,

    // "Write Data"                         -- Master --    -- Slave --
    output wire [AXI_DATA_WIDTH-1 : 0]      M_AXI_WDATA,      
    output wire                             M_AXI_WVALID,
    output wire [(AXI_DATA_WIDTH/8)-1:0]    M_AXI_WSTRB,
    input  wire                                             M_AXI_WREADY,

    // "Send Write Response"                -- Master --    -- Slave --
    input  wire [1 : 0]                                     M_AXI_BRESP,
    input  wire                                             M_AXI_BVALID,
    output wire                             M_AXI_BREADY,

    // "Specify read address"               -- Master --    -- Slave --
    output wire [AXI_ADDR_WIDTH-1 : 0]      M_AXI_ARADDR,     
    output wire                             M_AXI_ARVALID,
    output wire [2 : 0]                     M_AXI_ARPROT,     
    input  wire                                             M_AXI_ARREADY,

    // "Read data back to master"           -- Master --    -- Slave --
    input  wire [AXI_DATA_WIDTH-1 : 0]                      M_AXI_RDATA,
    input  wire                                             M_AXI_RVALID,
    input  wire [1 : 0]                                     M_AXI_RRESP,
    output wire                             M_AXI_RREADY,


    // Full AXI4 signals driven by master
    output wire[3:0]                        M_AXI_AWID,
    output wire[7:0]                        M_AXI_AWLEN,
    output wire[2:0]                        M_AXI_AWSIZE,
    output wire[1:0]                        M_AXI_AWBURST,
    output wire                             M_AXI_AWLOCK,
    output wire[3:0]                        M_AXI_AWCACHE,
    output wire[3:0]                        M_AXI_AWQOS,
    output wire                             M_AXI_WLAST,
    output wire                             M_AXI_ARLOCK,
    output wire[3:0]                        M_AXI_ARID,
    output wire[7:0]                        M_AXI_ARLEN,
    output wire[2:0]                        M_AXI_ARSIZE,
    output wire[1:0]                        M_AXI_ARBURST,
    output wire[3:0]                        M_AXI_ARCACHE,
    output wire[3:0]                        M_AXI_ARQOS,

    // Full AXI4 signals driven by slave
    input  wire                                             M_AXI_RLAST

    //==========================================================================

);

    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                From here to the next marker is generic AXI transaction logic
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><


    localparam AXI_DATA_BYTES = (AXI_DATA_WIDTH/8);

    // Assign all of the "write transaction" signals that aren't in the AXI4-Lite spec
    assign M_AXI_AWID    = 1;   // Arbitrary ID
    assign M_AXI_AWLEN   = 0;   // Burst length of 1
    assign M_AXI_AWSIZE  = 6;   // 6 = 64 bytes per burst (assuming  512-bit AXI data)
    assign M_AXI_WLAST   = 1;   // Each beat is always the last beat of the burst
    assign M_AXI_AWBURST = 1;   // Each beat of the burst increments by 1 address (ignored)
    assign M_AXI_AWLOCK  = 0;   // Normal signaling
    assign M_AXI_AWCACHE = 2;   // Normal, no cache, no buffer
    assign M_AXI_AWQOS   = 0;   // Lowest quality of service, unused

    // Assign all of the "read transaction" signals that aren't in the AXI4-Lite spec
    assign M_AXI_ARLOCK  = 0;   // Normal signaling
    assign M_AXI_ARID    = 1;   // Arbitrary ID
    assign M_AXI_ARLEN   = 0;   // Burst length of 1
    assign M_AXI_ARSIZE  = 6;   // 6 = 64 bytes per burst (assuming 512-bit AXI data)
    assign M_AXI_ARBURST = 1;   // Increment address on each beat of the burst (unused)
    assign M_AXI_ARCACHE = 2;   // Normal, no cache, no buffer
    assign M_AXI_ARQOS   = 0;   // Lowest quality of service (unused)


    // Define the handshakes for all 5 AXI channels
    wire B_HANDSHAKE  = M_AXI_BVALID  & M_AXI_BREADY;
    wire R_HANDSHAKE  = M_AXI_RVALID  & M_AXI_RREADY;
    wire W_HANDSHAKE  = M_AXI_WVALID  & M_AXI_WREADY;
    wire AR_HANDSHAKE = M_AXI_ARVALID & M_AXI_ARREADY;
    wire AW_HANDSHAKE = M_AXI_AWVALID & M_AXI_AWREADY;

    //=========================================================================================================
    // FSM logic used for writing to the slave device.
    //
    //  To start:   amci_waddr = Address to write to
    //              amci_wdata = Data to write at that address
    //              amci_write = Pulsed high for one cycle
    //
    //  At end:     Write is complete when "amci_widle" goes high
    //              amci_wresp = AXI_BRESP "write response" signal from slave
    //=========================================================================================================
    reg[1:0]                    write_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0]     amci_waddr;
    reg[AXI_DATA_WIDTH-1:0]     amci_wdata;
    reg                         amci_write;

    // FSM user interface outputs
    wire                        amci_widle = (write_state == 0 && amci_write == 0);     
    reg[1:0]                    amci_wresp;

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0]     m_axi_awaddr;
    reg[AXI_DATA_WIDTH-1:0]     m_axi_wdata;
    reg                         m_axi_awvalid = 0;
    reg                         m_axi_wvalid = 0;
    reg                         m_axi_bready = 0;

    // Wire up the AXI interface outputs
    assign M_AXI_AWADDR  = m_axi_awaddr;
    assign M_AXI_WDATA   = m_axi_wdata;
    assign M_AXI_AWVALID = m_axi_awvalid;
    assign M_AXI_WVALID  = m_axi_wvalid;
    assign M_AXI_AWPROT  = 3'b000;
    assign M_AXI_WSTRB   = (1 << AXI_DATA_BYTES) - 1; // usually 4'b1111
    assign M_AXI_BREADY  = m_axi_bready;
    //=========================================================================================================
     
    always @(posedge M_AXI_ACLK) begin

        // If we're in RESET mode...
        if (M_AXI_ARESETN == 0) begin
            write_state   <= 0;
            m_axi_awvalid <= 0;
            m_axi_wvalid  <= 0;
            m_axi_bready  <= 0;
        end        
        
        // Otherwise, we're not in RESET and our state machine is running
        else case (write_state)
            
            // Here we're idle, waiting for someone to raise the 'amci_write' flag.  Once that happens,
            // we'll place the user specified address and data onto the AXI bus, along with the flags that
            // indicate that the address and data values are valid
            0:  if (amci_write) begin
                    m_axi_awaddr    <= amci_waddr;  // Place our address onto the bus
                    m_axi_wdata     <= amci_wdata;  // Place our data onto the bus
                    m_axi_awvalid   <= 1;           // Indicate that the address is valid
                    m_axi_wvalid    <= 1;           // Indicate that the data is valid
                    m_axi_bready    <= 1;           // Indicate that we're ready for the slave to respond
                    write_state     <= 1;           // On the next clock cycle, we'll be in the next state
                end
                
           // Here, we're waiting around for the slave to acknowledge our request by asserting M_AXI_AWREADY
           // and M_AXI_WREADY.  Once that happens, we'll de-assert the "valid" lines.  Keep in mind that we
           // don't know what order AWREADY and WREADY will come in, and they could both come at the same
           // time.      
           1:   begin   
                    // Keep track of whether we have seen the slave raise AWREADY or WREADY
                    if (AW_HANDSHAKE) m_axi_awvalid <= 0;
                    if (W_HANDSHAKE ) m_axi_wvalid  <= 0;

                    // If we've seen AWREADY (or if its raised now) and if we've seen WREADY (or if it's raised now)...
                    if ((~m_axi_awvalid || AW_HANDSHAKE) && (~m_axi_wvalid || W_HANDSHAKE)) begin
                        write_state <= 2;
                    end
                end
                
           // Wait around for the slave to assert "M_AXI_BVALID".  When it does, we'll acknowledge
           // it by raising M_AXI_BREADY for one cycle, and go back to idle state
           2:   if (B_HANDSHAKE) begin
                    amci_wresp   <= M_AXI_BRESP;
                    m_axi_bready <= 0;
                    write_state  <= 0;
                end

        endcase
    end
    //=========================================================================================================





    //=========================================================================================================
    // FSM logic used for reading from a slave device.
    //
    //  To start:   amci_raddr = Address to read from
    //              amci_read  = Pulsed high for one cycle
    //
    //  At end:   Read is complete when "amci_ridle" goes high.
    //            amci_rdata = The data that was read
    //            amci_rresp = The AXI "read response" that is used to indicate success or failure
    //=========================================================================================================
    reg                         read_state = 0;

    // FSM user interface inputs
    reg[AXI_ADDR_WIDTH-1:0]     amci_raddr;
    reg                         amci_read;

    // FSM user interface outputs
    reg[AXI_DATA_WIDTH-1:0]     amci_rdata;
    reg[1:0]                    amci_rresp;
    wire                        amci_ridle = (read_state == 0 && amci_read == 0);     

    // AXI registers and outputs
    reg[AXI_ADDR_WIDTH-1:0]     m_axi_araddr;
    reg                         m_axi_arvalid = 0;
    reg                         m_axi_rready;

    // Wire up the AXI interface outputs
    assign M_AXI_ARADDR  = m_axi_araddr;
    assign M_AXI_ARVALID = m_axi_arvalid;
    assign M_AXI_ARPROT  = 3'b001;
    assign M_AXI_RREADY  = m_axi_rready;
    //=========================================================================================================
    always @(posedge M_AXI_ACLK) begin
         
        if (M_AXI_ARESETN == 0) begin
            read_state    <= 0;
            m_axi_arvalid <= 0;
            m_axi_rready  <= 0;
        end else case (read_state)

            // Here we are waiting around for someone to raise "amci_read", which signals us to begin
            // a AXI read at the address specified in "amci_raddr"
            0:  if (amci_read) begin
                    m_axi_araddr  <= amci_raddr;
                    m_axi_arvalid <= 1;
                    m_axi_rready  <= 1;
                    read_state    <= 1;
                end else begin
                    m_axi_arvalid <= 0;
                    m_axi_rready  <= 0;
                    read_state    <= 0;
                end
            
            // Wait around for the slave to raise M_AXI_RVALID, which tells us that M_AXI_RDATA
            // contains the data we requested
            1:  begin
                    if (AR_HANDSHAKE) begin
                        m_axi_arvalid <= 0;
                    end

                    if (R_HANDSHAKE) begin
                        amci_rdata    <= M_AXI_RDATA;
                        amci_rresp    <= M_AXI_RRESP;
                        m_axi_rready  <= 0;
                        read_state    <= 0;
                    end
                end

        endcase
    end
    //=========================================================================================================

    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //                                   End of AXI transaction logic
    //
    //                             From here down is module-specific logic
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    //<><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><><
    
    localparam BLOCK_SIZE = 16;

    // Assign some convenient (and standard) names to the clock and reset lines
    wire clk    = M_AXI_ACLK;
    wire resetn = M_AXI_ARESETN;

    // An AXI address that increments by 64 bytes (512 bits) on every clock cycle
    reg[34:0] random_addr = 34'h100000000;
    always @(posedge clk) random_addr <= random_addr + 64;

    reg[AXI_DATA_WIDTH-1:0] free_timer;
    always @(posedge clk) free_timer <= free_timer + 1;
   
    reg[AXI_DATA_WIDTH-1:0] data[0:BLOCK_SIZE-1];

    reg[2:0] state;
    reg[15:0] index;
    reg[AXI_ADDR_WIDTH-1:0] first_addr;

    reg alarm;  assign ALARM = alarm;

    always @(posedge clk) begin
        amci_write <= 0;
        amci_read  <= 0;
        if (resetn == 0) begin
            state <= 0;
            alarm <= 1;
        end else case(state)

        0:  if (BUTTON) begin
                alarm   <= 0;
                state   <= 1;
            end

        1:  begin
                first_addr  <= random_addr;
                amci_waddr  <= random_addr;
                amci_wdata  <= free_timer;
                data[0]     <= free_timer;
                amci_write  <= 1;
                state       <= state + 1;
                index       <= 1;
            end

        2:  if (amci_widle) begin
                if (index == BLOCK_SIZE) begin
                    amci_raddr <= first_addr;
                    amci_read  <= 1;
                    index      <= 0;
                    state      <= state + 1;
                end else begin
                    amci_waddr  <= amci_waddr + 64;
                    amci_wdata  <= free_timer;
                    data[index] <= free_timer;
                    amci_write  <= 1;
                    index       <= index + 1;
                end
            end

        3:  if (amci_ridle) begin
                if (amci_rdata == data[index]) begin
                    if (index == BLOCK_SIZE -1)
                        state <= 1;
                    else begin
                        index      <= index + 1;
                        amci_raddr <= amci_raddr + 64;
                        amci_read  <= 1;
                    end
                end else alarm <= 1;
            end
 
        endcase
    
    end



endmodule
