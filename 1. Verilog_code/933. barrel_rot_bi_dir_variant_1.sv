//SystemVerilog
module barrel_rot_bi_dir (
    input wire clk,              // Added clock for pipeline stages
    input wire rst_n,            // Added reset signal
    input wire [31:0] data_in,
    input wire [4:0] shift_val,
    input wire direction,        // 0-left, 1-right
    output reg [31:0] data_out   // Changed to reg for pipelined output
);
    // Stage 1: Calculate left/right rotation amounts
    reg [4:0] shift_left_amt;
    reg [4:0] shift_right_amt;
    reg [31:0] data_reg_s1;
    reg direction_s1;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_amt <= 5'b0;
            shift_right_amt <= 5'b0;
            data_reg_s1 <= 32'b0;
            direction_s1 <= 1'b0;
        end else begin
            shift_left_amt <= shift_val;
            shift_right_amt <= 5'd32 - shift_val;
            data_reg_s1 <= data_in;
            direction_s1 <= direction;
        end
    end
    
    // Stage 2: Perform partial rotations
    reg [31:0] shift_left_part1;
    reg [31:0] shift_left_part2;
    reg [31:0] shift_right_part1;
    reg [31:0] shift_right_part2;
    reg direction_s2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shift_left_part1 <= 32'b0;
            shift_left_part2 <= 32'b0;
            shift_right_part1 <= 32'b0;
            shift_right_part2 <= 32'b0;
            direction_s2 <= 1'b0;
        end else begin
            shift_left_part1 <= data_reg_s1 << shift_left_amt;
            shift_left_part2 <= data_reg_s1 >> shift_right_amt;
            shift_right_part1 <= data_reg_s1 >> shift_left_amt;
            shift_right_part2 <= data_reg_s1 << shift_right_amt;
            direction_s2 <= direction_s1;
        end
    end
    
    // Stage 3: Combine partial rotations and select direction
    reg [31:0] rot_left;
    reg [31:0] rot_right;
    reg direction_s3;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rot_left <= 32'b0;
            rot_right <= 32'b0;
            direction_s3 <= 1'b0;
        end else begin
            rot_left <= shift_left_part1 | shift_left_part2;
            rot_right <= shift_right_part1 | shift_right_part2;
            direction_s3 <= direction_s2;
        end
    end
    
    // Stage 4: Final output selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 32'b0;
        end else begin
            data_out <= direction_s3 ? rot_right : rot_left;
        end
    end

endmodule