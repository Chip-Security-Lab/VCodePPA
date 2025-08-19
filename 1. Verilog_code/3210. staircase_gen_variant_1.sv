//SystemVerilog
module staircase_gen(
    input clock,
    input reset_n,
    input [2:0] step_size,
    input [4:0] num_steps,
    output reg [7:0] staircase
);
    reg [4:0] step_counter;
    reg [2:0] step_size_buf;
    reg [4:0] num_steps_buf;
    
    always @(posedge clock or negedge reset_n) begin
        if (!reset_n) begin
            step_size_buf <= 3'b0;
            num_steps_buf <= 5'b0;
            staircase <= 8'h00;
            step_counter <= 5'h00;
        end else begin
            step_size_buf <= step_size;
            num_steps_buf <= num_steps;
            
            if (step_counter >= num_steps_buf) begin
                staircase <= 8'h00;
                step_counter <= 5'h00;
            end else begin
                staircase <= staircase + {5'b0, step_size_buf};
                step_counter <= step_counter + 5'h01;
            end
        end
    end
endmodule