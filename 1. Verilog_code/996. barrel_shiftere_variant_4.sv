//SystemVerilog
module barrel_shifter(
    input           clk,
    input           rst_n,
    input  [15:0]   din,
    input  [3:0]    shamt,
    input           dir,            // Direction: 0=right, 1=left
    output [15:0]   dout
);

    // Pipeline stage 0: Input latching
    reg  [15:0]    din_stage0;
    reg  [3:0]     shamt_stage0;
    reg            dir_stage0;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            din_stage0   <= 16'b0;
            shamt_stage0 <= 4'b0;
            dir_stage0   <= 1'b0;
        end else begin
            din_stage0   <= din;
            shamt_stage0 <= shamt;
            dir_stage0   <= dir;
        end
    end

    // Pipeline stage 1: shift by 1
    reg [15:0] stage1_data;
    reg [3:0]  stage1_shamt;
    reg        stage1_dir;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage1_data   <= 16'b0;
            stage1_shamt  <= 4'b0;
            stage1_dir    <= 1'b0;
        end else begin
            if (shamt_stage0[0]) begin
                if (dir_stage0) begin
                    stage1_data <= {din_stage0[14:0], din_stage0[15]};
                end else begin
                    stage1_data <= {din_stage0[0], din_stage0[15:1]};
                end
            end else begin
                stage1_data <= din_stage0;
            end
            stage1_shamt <= shamt_stage0;
            stage1_dir   <= dir_stage0;
        end
    end

    // Pipeline stage 2: shift by 2
    reg [15:0] stage2_data;
    reg [3:0]  stage2_shamt;
    reg        stage2_dir;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage2_data   <= 16'b0;
            stage2_shamt  <= 4'b0;
            stage2_dir    <= 1'b0;
        end else begin
            if (stage1_shamt[1]) begin
                if (stage1_dir) begin
                    stage2_data <= {stage1_data[13:0], stage1_data[15:14]};
                end else begin
                    stage2_data <= {stage1_data[1:0], stage1_data[15:2]};
                end
            end else begin
                stage2_data <= stage1_data;
            end
            stage2_shamt <= stage1_shamt;
            stage2_dir   <= stage1_dir;
        end
    end

    // Pipeline stage 3: shift by 4
    reg [15:0] stage3_data;
    reg [3:0]  stage3_shamt;
    reg        stage3_dir;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            stage3_data   <= 16'b0;
            stage3_shamt  <= 4'b0;
            stage3_dir    <= 1'b0;
        end else begin
            if (stage2_shamt[2]) begin
                if (stage2_dir) begin
                    stage3_data <= {stage2_data[11:0], stage2_data[15:12]};
                end else begin
                    stage3_data <= {stage2_data[3:0], stage2_data[15:4]};
                end
            end else begin
                stage3_data <= stage2_data;
            end
            stage3_shamt <= stage2_shamt;
            stage3_dir   <= stage2_dir;
        end
    end

    // Pipeline stage 4: shift by 8 and output
    reg [15:0] dout_reg;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            dout_reg <= 16'b0;
        end else begin
            if (stage3_shamt[3]) begin
                if (stage3_dir) begin
                    dout_reg <= {stage3_data[7:0], stage3_data[15:8]};
                end else begin
                    dout_reg <= {stage3_data[7:0], stage3_data[15:8]};
                end
            end else begin
                dout_reg <= stage3_data;
            end
        end
    end

    assign dout = dout_reg;

endmodule