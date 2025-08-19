//SystemVerilog
module sync_var_rotation_shifter (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data,
    input  wire [2:0]  rot_amount,
    input  wire        rot_direction, // 0=left, 1=right
    output reg  [7:0]  rotated_data
);

    // Pipeline Stage 1: Register input data and control
    reg [7:0] data_stage1;
    reg [2:0] rot_amount_stage1;
    reg       rot_direction_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1           <= 8'h00;
            rot_amount_stage1     <= 3'b000;
            rot_direction_stage1  <= 1'b0;
        end else begin
            data_stage1           <= data;
            rot_amount_stage1     <= rot_amount;
            rot_direction_stage1  <= rot_direction;
        end
    end

    // Pipeline Stage 2: Compute left and right rotations
    reg [7:0] right_rotated_stage2;
    reg [7:0] left_rotated_stage2;
    reg       rot_direction_stage2;

    // Right rotation combinational logic
    function [7:0] right_rotate;
        input [7:0] in_data;
        input [2:0] amount;
        case(amount)
            3'd0: right_rotate = in_data;
            3'd1: right_rotate = {in_data[0], in_data[7:1]};
            3'd2: right_rotate = {in_data[1:0], in_data[7:2]};
            3'd3: right_rotate = {in_data[2:0], in_data[7:3]};
            3'd4: right_rotate = {in_data[3:0], in_data[7:4]};
            3'd5: right_rotate = {in_data[4:0], in_data[7:5]};
            3'd6: right_rotate = {in_data[5:0], in_data[7:6]};
            3'd7: right_rotate = {in_data[6:0], in_data[7]};
            default: right_rotate = in_data;
        endcase
    endfunction

    // Left rotation combinational logic
    function [7:0] left_rotate;
        input [7:0] in_data;
        input [2:0] amount;
        case(amount)
            3'd0: left_rotate = in_data;
            3'd1: left_rotate = {in_data[6:0], in_data[7]};
            3'd2: left_rotate = {in_data[5:0], in_data[7:6]};
            3'd3: left_rotate = {in_data[4:0], in_data[7:5]};
            3'd4: left_rotate = {in_data[3:0], in_data[7:4]};
            3'd5: left_rotate = {in_data[2:0], in_data[7:3]};
            3'd6: left_rotate = {in_data[1:0], in_data[7:2]};
            3'd7: left_rotate = {in_data[0], in_data[7:1]};
            default: left_rotate = in_data;
        endcase
    endfunction

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_rotated_stage2   <= 8'h00;
            left_rotated_stage2    <= 8'h00;
            rot_direction_stage2   <= 1'b0;
        end else begin
            right_rotated_stage2   <= right_rotate(data_stage1, rot_amount_stage1);
            left_rotated_stage2    <= left_rotate(data_stage1, rot_amount_stage1);
            rot_direction_stage2   <= rot_direction_stage1;
        end
    end

    // Pipeline Stage 3: Select rotated data based on direction
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rotated_data <= 8'h00;
        end else begin
            if (rot_direction_stage2)
                rotated_data <= right_rotated_stage2;
            else
                rotated_data <= left_rotated_stage2;
        end
    end

endmodule