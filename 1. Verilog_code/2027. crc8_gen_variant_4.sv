//SystemVerilog
module crc8_gen (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  data_in,
    input  wire        data_valid,
    output reg  [7:0]  crc_out,
    output reg         crc_valid
);

    // Stage 1: Input XOR and valid pipeline
    reg [7:0] crc_stage1;
    reg       valid_stage1;

    // Stage 2: Final CRC computation and valid pipeline
    reg [7:0] crc_stage2;
    reg       valid_stage2;

    // For flush/startup
    wire flush;
    assign flush = !rst_n;

    // Stage 1: Compute crc_next = crc_out ^ data_in
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage1   <= 8'd0;
            valid_stage1 <= 1'b0;
        end else begin
            if (data_valid) begin
                crc_stage1   <= crc_out ^ data_in;
                valid_stage1 <= 1'b1;
            end else begin
                valid_stage1 <= 1'b0;
            end
        end
    end

    // Stage 2: Compute CRC polynomial operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_stage2   <= 8'd0;
            valid_stage2 <= 1'b0;
        end else begin
            if (valid_stage1) begin
                if (crc_stage1[7] == 1'b1) begin
                    crc_stage2 <= {crc_stage1[6:0], 1'b0} ^ 8'h07;
                end else begin
                    crc_stage2 <= {crc_stage1[6:0], 1'b0};
                end
                valid_stage2 <= 1'b1;
            end else begin
                valid_stage2 <= 1'b0;
            end
        end
    end

    // Output register (CRC and valid)
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            crc_out   <= 8'd0;
            crc_valid <= 1'b0;
        end else begin
            if (valid_stage2) begin
                crc_out   <= crc_stage2;
                crc_valid <= 1'b1;
            end else begin
                crc_valid <= 1'b0;
            end
        end
    end

endmodule