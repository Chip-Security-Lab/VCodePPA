//SystemVerilog
module sync_var_rotation_shifter (
    input              clk,
    input              rst_n,
    input      [7:0]   data,
    input      [2:0]   rot_amount,
    input              rot_direction, // 0=left, 1=right
    output reg [7:0]   rotated_data
);

    // Stage 1: Register Inputs
    reg [7:0]   data_stage1;
    reg [2:0]   rot_amount_stage1;
    reg         rot_direction_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1          <= 8'h0;
            rot_amount_stage1    <= 3'b0;
            rot_direction_stage1 <= 1'b0;
        end else begin
            data_stage1          <= data;
            rot_amount_stage1    <= rot_amount;
            rot_direction_stage1 <= rot_direction;
        end
    end

    // Stage 2: Generate right rotations
    reg [7:0] right_rot0_stage2, right_rot1_stage2, right_rot2_stage2, right_rot3_stage2;
    reg [7:0] right_rot4_stage2, right_rot5_stage2, right_rot6_stage2, right_rot7_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_rot0_stage2 <= 8'h0;
            right_rot1_stage2 <= 8'h0;
            right_rot2_stage2 <= 8'h0;
            right_rot3_stage2 <= 8'h0;
            right_rot4_stage2 <= 8'h0;
            right_rot5_stage2 <= 8'h0;
            right_rot6_stage2 <= 8'h0;
            right_rot7_stage2 <= 8'h0;
        end else begin
            right_rot0_stage2 <= data_stage1;
            right_rot1_stage2 <= {data_stage1[0],   data_stage1[7:1]};
            right_rot2_stage2 <= {data_stage1[1:0], data_stage1[7:2]};
            right_rot3_stage2 <= {data_stage1[2:0], data_stage1[7:3]};
            right_rot4_stage2 <= {data_stage1[3:0], data_stage1[7:4]};
            right_rot5_stage2 <= {data_stage1[4:0], data_stage1[7:5]};
            right_rot6_stage2 <= {data_stage1[5:0], data_stage1[7:6]};
            right_rot7_stage2 <= {data_stage1[6:0], data_stage1[7]};
        end
    end

    // Stage 2: Generate left rotations
    reg [7:0] left_rot0_stage2, left_rot1_stage2, left_rot2_stage2, left_rot3_stage2;
    reg [7:0] left_rot4_stage2, left_rot5_stage2, left_rot6_stage2, left_rot7_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_rot0_stage2 <= 8'h0;
            left_rot1_stage2 <= 8'h0;
            left_rot2_stage2 <= 8'h0;
            left_rot3_stage2 <= 8'h0;
            left_rot4_stage2 <= 8'h0;
            left_rot5_stage2 <= 8'h0;
            left_rot6_stage2 <= 8'h0;
            left_rot7_stage2 <= 8'h0;
        end else begin
            left_rot0_stage2 <= data_stage1;
            left_rot1_stage2 <= {data_stage1[6:0], data_stage1[7]};
            left_rot2_stage2 <= {data_stage1[5:0], data_stage1[7:6]};
            left_rot3_stage2 <= {data_stage1[4:0], data_stage1[7:5]};
            left_rot4_stage2 <= {data_stage1[3:0], data_stage1[7:4]};
            left_rot5_stage2 <= {data_stage1[2:0], data_stage1[7:3]};
            left_rot6_stage2 <= {data_stage1[1:0], data_stage1[7:2]};
            left_rot7_stage2 <= {data_stage1[0],   data_stage1[7:1]};
        end
    end

    // Stage 2: Register rot_amount and direction
    reg [2:0] rot_amount_stage2;
    reg       rot_direction_stage2;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rot_amount_stage2    <= 3'b0;
            rot_direction_stage2 <= 1'b0;
        end else begin
            rot_amount_stage2    <= rot_amount_stage1;
            rot_direction_stage2 <= rot_direction_stage1;
        end
    end

    // Stage 3: Right rotation selection
    reg [7:0] right_rotated_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            right_rotated_stage3 <= 8'h0;
        end else begin
            case(rot_amount_stage2)
                3'd0: right_rotated_stage3 <= right_rot0_stage2;
                3'd1: right_rotated_stage3 <= right_rot1_stage2;
                3'd2: right_rotated_stage3 <= right_rot2_stage2;
                3'd3: right_rotated_stage3 <= right_rot3_stage2;
                3'd4: right_rotated_stage3 <= right_rot4_stage2;
                3'd5: right_rotated_stage3 <= right_rot5_stage2;
                3'd6: right_rotated_stage3 <= right_rot6_stage2;
                3'd7: right_rotated_stage3 <= right_rot7_stage2;
                default: right_rotated_stage3 <= right_rot0_stage2;
            endcase
        end
    end

    // Stage 3: Left rotation selection
    reg [7:0] left_rotated_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_rotated_stage3 <= 8'h0;
        end else begin
            case(rot_amount_stage2)
                3'd0: left_rotated_stage3 <= left_rot0_stage2;
                3'd1: left_rotated_stage3 <= left_rot1_stage2;
                3'd2: left_rotated_stage3 <= left_rot2_stage2;
                3'd3: left_rotated_stage3 <= left_rot3_stage2;
                3'd4: left_rotated_stage3 <= left_rot4_stage2;
                3'd5: left_rotated_stage3 <= left_rot5_stage2;
                3'd6: left_rotated_stage3 <= left_rot6_stage2;
                3'd7: left_rotated_stage3 <= left_rot7_stage2;
                default: left_rotated_stage3 <= left_rot0_stage2;
            endcase
        end
    end

    // Stage 3: Register rot_direction
    reg rot_direction_stage3;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rot_direction_stage3 <= 1'b0;
        end else begin
            rot_direction_stage3 <= rot_direction_stage2;
        end
    end

    // Stage 4: Output selection and register output
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rotated_data <= 8'h0;
        end else begin
            if (rot_direction_stage3)
                rotated_data <= right_rotated_stage3;
            else
                rotated_data <= left_rotated_stage3;
        end
    end

endmodule