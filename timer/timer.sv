module timer(
    input logic clk,
    input logic rst,
    input logic enable, // Start counting when enable is high
    input logic [31:0] reload, // Value to load into the timer
    output logic time_pass // Goes high when timer reaches zero
);
    logic [31:0] counter;
    
    always_ff @(posedge clk or posedge rst) begin
        if (rst) begin
            counter <= 'b0;
            time_pass <= 1'b0;
        end else if (enable) begin
            if (counter == 32'd0) begin
                counter <= reload;
                time_pass <= 1'b1; // Indicate timer has passed
            end else begin
                counter <= counter - 1;
                time_pass <= 1'b0;
            end
        end else begin
            counter <= 32'd0;
            time_pass <= 1'b0;
        end
    end
  

endmodule
