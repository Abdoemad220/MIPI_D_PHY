`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 09/04/2025 06:55:22 PM
// Design Name: 
// Module Name: sync
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module sync(
        input wire clk,
        input wire rst,
        input wire unstable,
        output reg stable
    );

        reg stage2;
    always @(posedge rst or posedge clk) 
    begin
        if (rst)
        begin
            stable <= 0;
            stage2 <= 0;
        end
        else
        begin
            stage2 <= unstable;
            stable <= stage2;   
        end
    end

endmodule
