module staircase_gen(
    input clock,
    input reset_n,
    input [2:0] step_size,
    input [4:0] num_steps,
    output reg [7:0] staircase
);
    reg [4:0] step_counter;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            staircase <= 8'h00;
            step_counter <= 5'h00;
        end else begin
            if (step_counter >= num_steps) begin
                staircase <= 8'h00;
                step_counter <= 5'h00;
            end else begin
                staircase <= staircase + {5'b0, step_size};
                step_counter <= step_counter + 5'h01;
            end
        end
    end
endmodule