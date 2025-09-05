`timescale 1ns / 1ps


module mux #(parameter w = 2)(
    input wire [w-1:0] a,
    input wire [w-1:0] b,
    input wire s,
    output wire [w-1:0] c
    );

    assign c = s ? a : b;

endmodule
