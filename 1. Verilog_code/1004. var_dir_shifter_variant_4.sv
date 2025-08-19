//SystemVerilog

module var_dir_shifter(
    input  wire         clk,
    input  wire         rst_n,
    input  wire         in_valid,
    input  wire [15:0]  in_data,
    input  wire [3:0]   shift_amount,
    input  wire         direction,   // 0:right, 1:left
    input  wire         fill_value,  // Value to fill vacant bits
    output reg  [15:0]  out_data,
    output reg          out_valid
);

    // Pipeline Stage 1: Latch inputs
    reg [15:0] in_data_stage1;
    reg [3:0]  shift_amount_stage1;
    reg        direction_stage1;
    reg        fill_value_stage1;
    reg        valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_data_stage1       <= 16'd0;
            shift_amount_stage1  <= 4'd0;
            direction_stage1     <= 1'b0;
            fill_value_stage1    <= 1'b0;
            valid_stage1         <= 1'b0;
        end else begin
            in_data_stage1       <= in_data;
            shift_amount_stage1  <= shift_amount;
            direction_stage1     <= direction;
            fill_value_stage1    <= fill_value;
            valid_stage1         <= in_valid;
        end
    end

    // Pipeline Stage 2: Generate fills and perform shift
    reg [15:0] left_fill_stage2;
    reg [15:0] right_fill_stage2;
    reg [15:0] left_shifted_stage2;
    reg [15:0] right_shifted_stage2;
    reg        direction_stage2;
    reg        valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            left_fill_stage2     <= 16'd0;
            right_fill_stage2    <= 16'd0;
            left_shifted_stage2  <= 16'd0;
            right_shifted_stage2 <= 16'd0;
            direction_stage2     <= 1'b0;
            valid_stage2         <= 1'b0;
        end else begin
            left_fill_stage2     <= {16{fill_value_stage1}};
            right_fill_stage2    <= {16{fill_value_stage1}};
            left_shifted_stage2  <= (shift_amount_stage1 == 0) ? in_data_stage1 :
                                    ((in_data_stage1 << shift_amount_stage1) |
                                     (left_fill_stage2 & ~({16{1'b1}} << shift_amount_stage1)));
            right_shifted_stage2 <= (shift_amount_stage1 == 0) ? in_data_stage1 :
                                    ((in_data_stage1 >> shift_amount_stage1) |
                                     (right_fill_stage2 & ~({16{1'b1}} >> shift_amount_stage1)));
            direction_stage2     <= direction_stage1;
            valid_stage2         <= valid_stage1;
        end
    end

    // Pipeline Stage 3: Output selection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_data   <= 16'd0;
            out_valid  <= 1'b0;
        end else begin
            if (direction_stage2)
                out_data <= left_shifted_stage2;
            else
                out_data <= right_shifted_stage2;
            out_valid <= valid_stage2;
        end
    end

endmodule

module booth_multiplier_16bit (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         start,
    input  wire [15:0]  multiplicand,
    input  wire [15:0]  multiplier,
    output reg  [31:0]  product,
    output reg          done
);

    // Pipeline Stage 1: Latch inputs and initialize
    reg [15:0]  multiplicand_stage1;
    reg [15:0]  multiplier_stage1;
    reg         start_stage1;
    reg         valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            multiplicand_stage1 <= 16'd0;
            multiplier_stage1   <= 16'd0;
            start_stage1        <= 1'b0;
            valid_stage1        <= 1'b0;
        end else begin
            multiplicand_stage1 <= multiplicand;
            multiplier_stage1   <= multiplier;
            start_stage1        <= start;
            valid_stage1        <= start;
        end
    end

    // Pipeline Stage 2: Prepare booth operands
    reg [16:0] booth_A_stage2;
    reg [16:0] booth_S_stage2;
    reg [33:0] booth_P_stage2;
    reg [4:0]  booth_count_stage2;
    reg        running_stage2;
    reg        valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_A_stage2      <= 17'd0;
            booth_S_stage2      <= 17'd0;
            booth_P_stage2      <= 34'd0;
            booth_count_stage2  <= 5'd0;
            running_stage2      <= 1'b0;
            valid_stage2        <= 1'b0;
        end else begin
            if (valid_stage1) begin
                booth_A_stage2      <= {multiplicand_stage1[15], multiplicand_stage1};
                booth_S_stage2      <= {~multiplicand_stage1[15], (~multiplicand_stage1) + 1'b1};
                booth_P_stage2      <= {17'd0, multiplier_stage1, 1'b0};
                booth_count_stage2  <= 5'd16;
                running_stage2      <= 1'b1;
                valid_stage2        <= 1'b1;
            end else begin
                booth_A_stage2      <= booth_A_stage2;
                booth_S_stage2      <= booth_S_stage2;
                booth_P_stage2      <= booth_P_stage2;
                booth_count_stage2  <= booth_count_stage2;
                running_stage2      <= running_stage2;
                valid_stage2        <= 1'b0;
            end
        end
    end

    // Pipeline Stage 3: Booth's iteration (one iteration per clock)
    reg [16:0] booth_A_stage3;
    reg [16:0] booth_S_stage3;
    reg [33:0] booth_P_stage3;
    reg [4:0]  booth_count_stage3;
    reg        running_stage3;
    reg        done_stage3;
    reg        valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            booth_A_stage3      <= 17'd0;
            booth_S_stage3      <= 17'd0;
            booth_P_stage3      <= 34'd0;
            booth_count_stage3  <= 5'd0;
            running_stage3      <= 1'b0;
            done_stage3         <= 1'b0;
            valid_stage3        <= 1'b0;
        end else begin
            if (valid_stage2) begin
                booth_A_stage3      <= booth_A_stage2;
                booth_S_stage3      <= booth_S_stage2;
                booth_P_stage3      <= booth_P_stage2;
                booth_count_stage3  <= booth_count_stage2;
                running_stage3      <= running_stage2;
                done_stage3         <= 1'b0;
                valid_stage3        <= 1'b1;
            end else if (running_stage3) begin
                case (booth_P_stage3[1:0])
                    2'b01: booth_P_stage3[33:17] <= booth_P_stage3[33:17] + booth_A_stage3;
                    2'b10: booth_P_stage3[33:17] <= booth_P_stage3[33:17] + booth_S_stage3;
                    default: ;
                endcase
                booth_P_stage3      <= {booth_P_stage3[33], booth_P_stage3[33:1]};
                booth_count_stage3  <= booth_count_stage3 - 1'b1;
                if (booth_count_stage3 == 5'd1) begin
                    running_stage3  <= 1'b0;
                    done_stage3     <= 1'b1;
                end else begin
                    running_stage3  <= 1'b1;
                    done_stage3     <= 1'b0;
                end
                valid_stage3        <= 1'b1;
            end else begin
                done_stage3         <= 1'b0;
                valid_stage3        <= 1'b0;
            end
        end
    end

    // Pipeline Stage 4: Output latch
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            product <= 32'd0;
            done    <= 1'b0;
        end else begin
            if (done_stage3) begin
                product <= booth_P_stage3[32:1];
                done    <= 1'b1;
            end else begin
                done    <= 1'b0;
            end
        end
    end

endmodule