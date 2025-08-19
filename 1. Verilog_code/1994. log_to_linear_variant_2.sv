//SystemVerilog
module log_to_linear #(
    parameter WIDTH = 8,
    parameter LUT_SIZE = 16
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire [WIDTH-1:0]       log_in,
    input  wire                   log_in_valid,
    output reg  [WIDTH-1:0]       linear_out,
    output reg                    linear_out_valid
);

    // LUT storage
    reg [WIDTH-1:0] lut [0:LUT_SIZE-1];
    integer i;
    initial begin : LUT_INIT
        for (i = 0; i < LUT_SIZE; i = i + 1) begin
            lut[i] = (1 << (i/2)); // 简化的指数算法
        end
    end

    // Pipeline Stage 1: Input Latching
    reg [WIDTH-1:0] log_in_stage1;
    reg             log_in_valid_stage1;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log_in_stage1       <= {WIDTH{1'b0}};
            log_in_valid_stage1 <= 1'b0;
        end else begin
            log_in_stage1       <= log_in;
            log_in_valid_stage1 <= log_in_valid;
        end
    end

    // Pipeline Stage 2: Index Check and Data Preparation
    reg [WIDTH-1:0] log_in_stage2;
    reg             log_in_valid_stage2;
    reg             lut_index_valid_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            log_in_stage2          <= {WIDTH{1'b0}};
            log_in_valid_stage2    <= 1'b0;
            lut_index_valid_stage2 <= 1'b0;
        end else begin
            log_in_stage2          <= log_in_stage1;
            log_in_valid_stage2    <= log_in_valid_stage1;
            if (log_in_valid_stage1)
                lut_index_valid_stage2 <= (log_in_stage1 < LUT_SIZE) ? 1'b1 : 1'b0;
            else
                lut_index_valid_stage2 <= 1'b0;
        end
    end

    // Pipeline Stage 3: LUT Read
    reg [WIDTH-1:0] lut_data_stage3;
    reg             lut_data_valid_stage3;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            lut_data_stage3      <= {WIDTH{1'b0}};
            lut_data_valid_stage3<= 1'b0;
        end else begin
            if (log_in_valid_stage2) begin
                if (lut_index_valid_stage2)
                    lut_data_stage3 <= lut[log_in_stage2];
                else
                    lut_data_stage3 <= {WIDTH{1'b1}};
                lut_data_valid_stage3 <= 1'b1;
            end else begin
                lut_data_stage3      <= {WIDTH{1'b0}};
                lut_data_valid_stage3<= 1'b0;
            end
        end
    end

    // Pipeline Stage 4: Output Register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            linear_out       <= {WIDTH{1'b0}};
            linear_out_valid <= 1'b0;
        end else begin
            linear_out       <= lut_data_stage3;
            linear_out_valid <= lut_data_valid_stage3;
        end
    end

endmodule