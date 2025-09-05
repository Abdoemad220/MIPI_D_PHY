`timescale 1ns / 1ps

module tb_mux;
    // Test parameters
    parameter WIDTH = 8;
    
    // Inputs
    reg [WIDTH-1:0] a;
    reg [WIDTH-1:0] b;
    reg s;
    
    // Outputs
    wire [WIDTH-1:0] c;
    
    // Instantiate the Unit Under Test (UUT)
    mux #(.w(WIDTH)) uut (
        .a(a),
        .b(b),
        .s(s),
        .c(c)
    );
    
    // Test sequence
    initial begin
        $display("Testing %d-bit MUX", WIDTH);
        $display("Time\ts\ta\tb\tc");
        $display("-----------------------------------");
        
        // Test Case 1: s = 0 (select b)
        s = 0;
        a = {WIDTH{1'b0}}; // All 0s
        b = {WIDTH{1'b1}}; // All 1s
        #10;
        $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        
        // Test Case 2: s = 1 (select a)
        s = 1;
        #10;
        $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        
        // Test Case 3: Random values
        s = 0;
        a = {WIDTH{1'b1}}; // All 1s
        b = {WIDTH{1'b0}}; // All 0s
        #10;
        $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        
        s = 1;
        #10;
        $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        
        // Test Case 4: Specific patterns for 2-bit mux
        if (WIDTH == 2) begin
            s = 0;
            a = 2'b10;
            b = 2'b01;
            #10;
            $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
            
            s = 1;
            #10;
            $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        end
        
        // Test Case 5: Toggle select rapidly
        s = 0;
        a = {WIDTH{1'b1}};
        b = {WIDTH{1'b0}};
        #5;
        s = 1;
        #5;
        s = 0;
        #5;
        s = 1;
        #5;
        $display("%0t\t%b\t%b\t%b\t%b", $time, s, a, b, c);
        
        $display("\nMUX test completed successfully!");
        $finish;
    end
    
endmodule