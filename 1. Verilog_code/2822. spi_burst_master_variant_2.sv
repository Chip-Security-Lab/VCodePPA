//SystemVerilog
module spi_burst_master #(
    parameter DATA_WIDTH = 8,
    parameter BURST_SIZE = 4
)(
    input clk,
    input rst_n,
    input [DATA_WIDTH-1:0] tx_data [BURST_SIZE-1:0],
    input burst_start,
    output reg [DATA_WIDTH-1:0] rx_data [BURST_SIZE-1:0],
    output reg burst_done,

    output sclk,
    output cs_n,
    output mosi,
    input miso
);

    // 合并流水线：控制、移位、采样、输出合并为两级

    // Stage 1: 控制与数据路径
    reg busy_stage1;
    reg burst_start_stage1;
    reg [$clog2(DATA_WIDTH)-1:0] bit_count_stage1;
    reg [$clog2(BURST_SIZE)-1:0] burst_count_stage1;
    reg [DATA_WIDTH-1:0] shift_reg_stage1;
    reg sclk_int_stage1;
    reg [DATA_WIDTH-1:0] rx_data_stage1 [BURST_SIZE-1:0];
    reg valid_stage1, flush_stage1;
    reg burst_done_stage1;

    // SCLK & MOSI assignments
    assign sclk = busy_stage1 ? sclk_int_stage1 : 1'b0;
    assign cs_n = ~busy_stage1;
    assign mosi = shift_reg_stage1[DATA_WIDTH-1];

    integer i;

    // 带状进位加法器子模块实例声明
    wire [DATA_WIDTH-1:0] bca_sum;
    wire bca_cout;
    reg [DATA_WIDTH-1:0] adder_a;
    reg [DATA_WIDTH-1:0] adder_b;
    reg adder_cin;

    bca_adder_8 u_bca_adder_8 (
        .a(adder_a),
        .b(adder_b),
        .cin(adder_cin),
        .sum(bca_sum),
        .cout(bca_cout)
    );

    // Stage 1: 控制、移位、采样、数据收集
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            busy_stage1 <= 1'b0;
            burst_start_stage1 <= 1'b0;
            bit_count_stage1 <= {($clog2(DATA_WIDTH)){1'b0}};
            burst_count_stage1 <= {($clog2(BURST_SIZE)){1'b0}};
            shift_reg_stage1 <= {DATA_WIDTH{1'b0}};
            sclk_int_stage1 <= 1'b0;
            valid_stage1 <= 1'b0;
            flush_stage1 <= 1'b0;
            burst_done_stage1 <= 1'b0;
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data_stage1[i] <= {DATA_WIDTH{1'b0}};
            adder_a <= {DATA_WIDTH{1'b0}};
            adder_b <= {DATA_WIDTH{1'b0}};
            adder_cin <= 1'b0;
        end else begin
            // 启动
            if (burst_start && !busy_stage1) begin
                busy_stage1 <= 1'b1;
                burst_start_stage1 <= 1'b1;
                burst_count_stage1 <= {($clog2(BURST_SIZE)){1'b0}};
                bit_count_stage1 <= DATA_WIDTH-1;
                shift_reg_stage1 <= tx_data[0];
                sclk_int_stage1 <= 1'b0;
                valid_stage1 <= 1'b1;
                flush_stage1 <= 1'b0;
                burst_done_stage1 <= 1'b0;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data_stage1[i] <= {DATA_WIDTH{1'b0}};
            end else if (busy_stage1) begin
                burst_start_stage1 <= 1'b0;
                valid_stage1 <= 1'b1;
                flush_stage1 <= 1'b0;
                burst_done_stage1 <= 1'b0;
                sclk_int_stage1 <= ~sclk_int_stage1;

                if (!sclk_int_stage1) begin // Rising edge
                    shift_reg_stage1 <= {shift_reg_stage1[DATA_WIDTH-2:0], 1'b0};
                    bit_count_stage1 <= bit_count_stage1 - 1;
                    if (bit_count_stage1 == 0) begin
                        if (burst_count_stage1 == BURST_SIZE-1) begin
                            busy_stage1 <= 1'b0;
                            burst_done_stage1 <= 1'b1;
                        end else begin
                            // 带状进位加法器实现 burst_count_stage1 + 1
                            adder_a <= { { (DATA_WIDTH-($clog2(BURST_SIZE))) {1'b0} }, burst_count_stage1 };
                            adder_b <= { { (DATA_WIDTH-($clog2(BURST_SIZE))) {1'b0} }, {{($clog2(BURST_SIZE)-1){1'b0}}, 1'b1} };
                            adder_cin <= 1'b0;
                            burst_count_stage1 <= bca_sum[$clog2(BURST_SIZE)-1:0];
                            bit_count_stage1 <= DATA_WIDTH-1;
                            shift_reg_stage1 <= tx_data[bca_sum[$clog2(BURST_SIZE)-1:0]];
                        end
                    end
                end else begin // Falling edge
                    if (bit_count_stage1 != DATA_WIDTH-1)
                        rx_data_stage1[burst_count_stage1][bit_count_stage1] <= miso;
                    // Keep previous value for first bit
                end
            end else begin
                burst_start_stage1 <= 1'b0;
                valid_stage1 <= 1'b0;
                flush_stage1 <= 1'b1;
                burst_done_stage1 <= 1'b0;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data_stage1[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // Stage 2: 输出寄存器
    reg [DATA_WIDTH-1:0] rx_data_stage2 [BURST_SIZE-1:0];
    reg burst_done_stage2;
    reg valid_stage2, flush_stage2;

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_done_stage2 <= 1'b0;
            valid_stage2 <= 1'b0;
            flush_stage2 <= 1'b0;
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data_stage2[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (flush_stage1) begin
                burst_done_stage2 <= 1'b0;
                valid_stage2 <= 1'b0;
                flush_stage2 <= 1'b1;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data_stage2[i] <= {DATA_WIDTH{1'b0}};
            end else if (valid_stage1) begin
                burst_done_stage2 <= burst_done_stage1;
                valid_stage2 <= 1'b1;
                flush_stage2 <= 1'b0;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data_stage2[i] <= rx_data_stage1[i];
            end else begin
                burst_done_stage2 <= 1'b0;
                valid_stage2 <= 1'b0;
                flush_stage2 <= 1'b1;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data_stage2[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

    // Output logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            burst_done <= 1'b0;
            for (i = 0; i < BURST_SIZE; i = i + 1)
                rx_data[i] <= {DATA_WIDTH{1'b0}};
        end else begin
            if (valid_stage2) begin
                burst_done <= burst_done_stage2;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data[i] <= rx_data_stage2[i];
            end else if (flush_stage2) begin
                burst_done <= 1'b0;
                for (i = 0; i < BURST_SIZE; i = i + 1)
                    rx_data[i] <= {DATA_WIDTH{1'b0}};
            end
        end
    end

endmodule

// 8位带状进位加法器实现
module bca_adder_8 (
    input  [7:0] a,
    input  [7:0] b,
    input        cin,
    output [7:0] sum,
    output       cout
);
    wire [7:0] g, p;
    wire [7:0] c;

    assign g = a & b;
    assign p = a ^ b;

    assign c[0] = cin;
    assign c[1] = g[0] | (p[0] & c[0]);
    assign c[2] = g[1] | (p[1] & g[0]) | (p[1] & p[0] & c[0]);
    assign c[3] = g[2] | (p[2] & g[1]) | (p[2] & p[1] & g[0]) | (p[2] & p[1] & p[0] & c[0]);
    assign c[4] = g[3] | (p[3] & g[2]) | (p[3] & p[2] & g[1]) | (p[3] & p[2] & p[1] & g[0]) | (p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[5] = g[4] | (p[4] & g[3]) | (p[4] & p[3] & g[2]) | (p[4] & p[3] & p[2] & g[1]) | (p[4] & p[3] & p[2] & p[1] & g[0]) | (p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[6] = g[5] | (p[5] & g[4]) | (p[5] & p[4] & g[3]) | (p[5] & p[4] & p[3] & g[2]) | (p[5] & p[4] & p[3] & p[2] & g[1]) | (p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign c[7] = g[6] | (p[6] & g[5]) | (p[6] & p[5] & g[4]) | (p[6] & p[5] & p[4] & g[3]) | (p[6] & p[5] & p[4] & p[3] & g[2]) | (p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);
    assign cout = g[7] | (p[7] & g[6]) | (p[7] & p[6] & g[5]) | (p[7] & p[6] & p[5] & g[4]) | (p[7] & p[6] & p[5] & p[4] & g[3]) | (p[7] & p[6] & p[5] & p[4] & p[3] & g[2]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & g[1]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & g[0]) | (p[7] & p[6] & p[5] & p[4] & p[3] & p[2] & p[1] & p[0] & c[0]);

    assign sum = p ^ c;

endmodule