//SystemVerilog
module mode_selectable_comparator(
    input [15:0] input_a,
    input [15:0] input_b,
    input signed_mode,
    input clk,
    input rst_n,
    input req,           // Request signal
    output reg ack,      // Acknowledge signal
    output reg is_equal,
    output reg is_greater,
    output reg is_less
);
    // Pipeline stage 1: Register inputs and mode
    reg [15:0] input_a_reg, input_b_reg;
    reg signed_mode_reg;
    reg req_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            input_a_reg <= 16'b0;
            input_b_reg <= 16'b0;
            signed_mode_reg <= 1'b0;
            req_reg <= 1'b0;
        end else begin
            input_a_reg <= input_a;
            input_b_reg <= input_b;
            signed_mode_reg <= signed_mode;
            req_reg <= req;
        end
    end
    
    // Pipeline stage 2: Perform comparisons in parallel paths
    wire unsigned_path_eq, unsigned_path_gt, unsigned_path_lt;
    wire signed_path_eq, signed_path_gt, signed_path_lt;
    
    assign unsigned_path_eq = (input_a_reg == input_b_reg);
    assign unsigned_path_gt = (input_a_reg > input_b_reg);
    assign unsigned_path_lt = (input_a_reg < input_b_reg);
    
    assign signed_path_eq = (input_a_reg == input_b_reg);
    assign signed_path_gt = ($signed(input_a_reg) > $signed(input_b_reg));
    assign signed_path_lt = ($signed(input_a_reg) < $signed(input_b_reg));
    
    // Pipeline stage 3: Register comparison results
    reg unsigned_eq_reg, unsigned_gt_reg, unsigned_lt_reg;
    reg signed_eq_reg, signed_gt_reg, signed_lt_reg;
    reg mode_pipe_reg;
    reg req_pipe_reg;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            unsigned_eq_reg <= 1'b0;
            unsigned_gt_reg <= 1'b0;
            unsigned_lt_reg <= 1'b0;
            signed_eq_reg <= 1'b0;
            signed_gt_reg <= 1'b0;
            signed_lt_reg <= 1'b0;
            mode_pipe_reg <= 1'b0;
            req_pipe_reg <= 1'b0;
        end else begin
            unsigned_eq_reg <= unsigned_path_eq;
            unsigned_gt_reg <= unsigned_path_gt;
            unsigned_lt_reg <= unsigned_path_lt;
            signed_eq_reg <= signed_path_eq;
            signed_gt_reg <= signed_path_gt;
            signed_lt_reg <= signed_path_lt;
            mode_pipe_reg <= signed_mode_reg;
            req_pipe_reg <= req_reg;
        end
    end
    
    // Pipeline stage 4: Final output multiplexing based on mode
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            is_equal <= 1'b0;
            is_greater <= 1'b0;
            is_less <= 1'b0;
            ack <= 1'b0;
        end else begin
            if (req_pipe_reg) begin
                is_equal <= mode_pipe_reg ? signed_eq_reg : unsigned_eq_reg;
                is_greater <= mode_pipe_reg ? signed_gt_reg : unsigned_gt_reg;
                is_less <= mode_pipe_reg ? signed_lt_reg : unsigned_lt_reg;
                ack <= 1'b1;
            end else begin
                ack <= 1'b0;
            end
        end
    end
endmodule