//SystemVerilog
module barrel_shifter(
    input              clk,
    input              rst_n,
    input      [15:0]  din,
    input      [3:0]   shift_amt,
    input              direction,        // 0=right, 1=left
    output reg [15:0]  dout
);

    // Pipeline Stage 0: Register input
    reg [15:0] din_stage0;
    reg [3:0]  shift_amt_stage0;
    reg        direction_stage0;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage0         <= 16'b0;
            shift_amt_stage0   <= 4'b0;
            direction_stage0   <= 1'b0;
        end else begin
            din_stage0         <= din;
            shift_amt_stage0   <= shift_amt;
            direction_stage0   <= direction;
        end
    end

    // Pipeline Stage 1: First shift (by 1)
    reg [15:0] data_stage1;
    reg [3:0]  shift_amt_stage1;
    reg        direction_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1        <= 16'b0;
            shift_amt_stage1   <= 4'b0;
            direction_stage1   <= 1'b0;
        end else begin
            if (shift_amt_stage0[0] && direction_stage0)
                data_stage1 <= {din_stage0[14:0], din_stage0[15]};
            else if (shift_amt_stage0[0] && !direction_stage0)
                data_stage1 <= {din_stage0[0], din_stage0[15:1]};
            else
                data_stage1 <= din_stage0;
            shift_amt_stage1   <= shift_amt_stage0;
            direction_stage1   <= direction_stage0;
        end
    end

    // Pipeline Stage 2: Second shift (by 2)
    reg [15:0] data_stage2;
    reg [3:0]  shift_amt_stage2;
    reg        direction_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2        <= 16'b0;
            shift_amt_stage2   <= 4'b0;
            direction_stage2   <= 1'b0;
        end else begin
            if (shift_amt_stage1[1] && direction_stage1)
                data_stage2 <= {data_stage1[13:0], data_stage1[15:14]};
            else if (shift_amt_stage1[1] && !direction_stage1)
                data_stage2 <= {data_stage1[1:0], data_stage1[15:2]};
            else
                data_stage2 <= data_stage1;
            shift_amt_stage2   <= shift_amt_stage1;
            direction_stage2   <= direction_stage1;
        end
    end

    // Pipeline Stage 3: Third shift (by 4)
    reg [15:0] data_stage3;
    reg [3:0]  shift_amt_stage3;
    reg        direction_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage3        <= 16'b0;
            shift_amt_stage3   <= 4'b0;
            direction_stage3   <= 1'b0;
        end else begin
            if (shift_amt_stage2[2] && direction_stage2)
                data_stage3 <= {data_stage2[11:0], data_stage2[15:12]};
            else if (shift_amt_stage2[2] && !direction_stage2)
                data_stage3 <= {data_stage2[3:0], data_stage2[15:4]};
            else
                data_stage3 <= data_stage2;
            shift_amt_stage3   <= shift_amt_stage2;
            direction_stage3   <= direction_stage2;
        end
    end

    // Pipeline Stage 4: Final shift (by 8) and output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout <= 16'b0;
        end else begin
            if (shift_amt_stage3[3])
                dout <= {data_stage3[7:0], data_stage3[15:8]};
            else
                dout <= data_stage3;
        end
    end

endmodule