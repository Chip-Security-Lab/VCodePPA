//SystemVerilog
module dram_ctrl_ecc #(
    parameter DATA_WIDTH = 64,
    parameter ECC_WIDTH = 8
)(
    input clk,
    input rst_n,
    input valid_in,
    output ready_out,
    input [DATA_WIDTH-1:0] data_in,
    output reg valid_out,
    input ready_in,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg [ECC_WIDTH-1:0] ecc_syndrome
);

    // Pipeline stage signals
    reg [DATA_WIDTH-1:0] data_stage1;
    reg [DATA_WIDTH-1:0] data_stage2;
    reg [ECC_WIDTH-1:0] ecc_stage1;
    reg [ECC_WIDTH-1:0] ecc_stage2;
    reg valid_stage1;
    reg valid_stage2;
    wire ready_stage1;
    wire ready_stage2;

    // Pre-calculate ECC masks
    wire [DATA_WIDTH-1:0] ecc_mask = 64'hFF00FF00FF00FF00;
    wire [DATA_WIDTH-1:0] data_ecc1;
    wire [DATA_WIDTH-1:0] data_ecc2;

    // Parallel ECC calculation
    assign data_ecc1 = data_in & ecc_mask;
    assign data_ecc2 = data_stage1 & ecc_mask;

    // Stage 1: Data register and initial ECC calculation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1 <= 0;
            ecc_stage1 <= 0;
            valid_stage1 <= 0;
        end else if (ready_stage1) begin
            data_stage1 <= data_in;
            ecc_stage1 <= ^data_ecc1;
            valid_stage1 <= valid_in;
        end
    end

    // Stage 2: ECC calculation and error detection
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage2 <= 0;
            ecc_stage2 <= 0;
            valid_stage2 <= 0;
        end else if (ready_stage2) begin
            data_stage2 <= data_stage1;
            ecc_stage2 <= ^data_ecc2;
            valid_stage2 <= valid_stage1;
        end
    end

    // Output stage with parallel syndrome calculation
    wire [ECC_WIDTH-1:0] syndrome = ecc_stage1 ^ ecc_stage2;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 0;
            ecc_syndrome <= 0;
            valid_out <= 0;
        end else if (ready_in) begin
            data_out <= data_stage2;
            ecc_syndrome <= syndrome;
            valid_out <= valid_stage2;
        end
    end

    // Optimized ready signal generation
    wire stage1_ready = !valid_stage1;
    wire stage2_ready = !valid_stage2;
    
    assign ready_stage1 = stage1_ready || (stage2_ready && ready_in);
    assign ready_stage2 = stage2_ready || ready_in;
    assign ready_out = ready_stage1;

endmodule