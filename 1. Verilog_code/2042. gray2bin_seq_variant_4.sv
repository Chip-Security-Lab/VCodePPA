//SystemVerilog
module gray2bin_seq_pipelined #(parameter DATA_W = 8) (
    input  wire                  clk,
    input  wire                  rst_n,
    input  wire                  enable,
    input  wire [DATA_W-1:0]     gray_code,
    output reg  [DATA_W-1:0]     binary_out
);

    // Stage 1 registers
    reg [DATA_W-1:0] gray_code_stage1;
    reg              enable_stage1;

    // Stage 2 registers
    reg [DATA_W-1:0] binary_stage2;
    reg [DATA_W-2:0] gray_stage2;
    reg              enable_stage2;

    // Stage 3 registers
    reg [DATA_W-1:0] binary_stage3;
    reg [DATA_W-3:0] gray_stage3;
    reg              enable_stage3;

    // Stage 4 registers
    reg [DATA_W-1:0] binary_stage4;
    reg              enable_stage4;

    // Stage 1: Latch input and stage enable
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_code_stage1 <= {DATA_W{1'b0}};
        end else begin
            gray_code_stage1 <= gray_code;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage1 <= 1'b0;
        end else begin
            enable_stage1 <= enable;
        end
    end

    // Stage 2: Compute MSB of binary and latch gray[DATA_W-2:0]
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage2 <= {DATA_W{1'b0}};
        end else begin
            binary_stage2[DATA_W-1] <= gray_code_stage1[DATA_W-1];
            binary_stage2[DATA_W-2:0] <= {DATA_W-1{1'b0}};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage2 <= {(DATA_W-1){1'b0}};
        end else begin
            gray_stage2 <= gray_code_stage1[DATA_W-2:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage2 <= 1'b0;
        end else begin
            enable_stage2 <= enable_stage1;
        end
    end

    // Stage 3: Compute next significant bit and propagate
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage3 <= {DATA_W{1'b0}};
        end else begin
            binary_stage3[DATA_W-1] <= binary_stage2[DATA_W-1];
            binary_stage3[DATA_W-2] <= binary_stage2[DATA_W-1] ^ gray_stage2[DATA_W-2];
            binary_stage3[DATA_W-3:0] <= {DATA_W-3{1'b0}};
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            gray_stage3 <= {(DATA_W-2){1'b0}};
        end else begin
            gray_stage3 <= gray_stage2[DATA_W-3:0];
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage3 <= 1'b0;
        end else begin
            enable_stage3 <= enable_stage2;
        end
    end

    // Stage 4: Compute remaining bits in parallel
    integer j;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            binary_stage4 <= {DATA_W{1'b0}};
        end else begin
            binary_stage4[DATA_W-1] <= binary_stage3[DATA_W-1];
            binary_stage4[DATA_W-2] <= binary_stage3[DATA_W-2];
            for (j = DATA_W-3; j >= 0; j = j - 1) begin
                if (j == DATA_W-3)
                    binary_stage4[j] <= binary_stage3[j+1] ^ gray_stage3[j];
                else
                    binary_stage4[j] <= binary_stage4[j+1] ^ gray_stage3[j];
            end
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            enable_stage4 <= 1'b0;
        end else begin
            enable_stage4 <= enable_stage3;
        end
    end

    // Stage 5: Output register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            binary_out <= {DATA_W{1'b0}};
        else if (enable_stage4)
            binary_out <= binary_stage4;
    end

endmodule