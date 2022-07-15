`timescale 1ns / 1ps


module blinker#
(
    parameter integer CLOCK_FREQ = 100000000
)
(
    input wire CLK, RESETN,
    output wire LED
);


    reg led = 0; assign LED = led;
    reg[31:0] counter = 0;

    always @(posedge CLK) begin
        if (RESETN == 0)
            counter <= 0;
        else if (counter)
            counter <= counter - 1;
        else begin
            led     <= ~led;
            counter <= CLOCK_FREQ/5;
        end
    end


endmodule
