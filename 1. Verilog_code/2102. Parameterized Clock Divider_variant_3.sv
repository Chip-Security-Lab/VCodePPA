//SystemVerilog
module param_clock_divider #(
    parameter DIVISOR = 4,
    parameter WIDTH = $clog2(DIVISOR)
)(
    input wire clk_in,
    input wire rst_n,
    output reg clk_out
);
    // Main counter and clock output registers
    reg [WIDTH-1:0] counter_reg;
    reg clk_out_reg;

    // Buffered combinational signals (high fanout buffer stage 1)
    reg [WIDTH-1:0] counter_comb_buf1;
    reg clk_out_comb_buf1;
    reg clk_out_reg_buf1;

    // Buffered combinational signals (high fanout buffer stage 2)
    reg [WIDTH-1:0] counter_comb_buf2;
    reg clk_out_comb_buf2;
    reg clk_out_reg_buf2;

    // Combination logic for next-state calculation
    reg [WIDTH-1:0] counter_comb;
    reg clk_out_comb;

    always @* begin
        if (counter_reg == (DIVISOR-1)) begin
            counter_comb = {WIDTH{1'b0}};
            clk_out_comb = ~clk_out_reg;
        end else begin
            counter_comb = counter_reg + 1'b1;
            clk_out_comb = clk_out_reg;
        end
    end

    // Buffer stage 1: Register the high fanout combinational signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_comb_buf1 <= {WIDTH{1'b0}};
            clk_out_comb_buf1 <= 1'b0;
            clk_out_reg_buf1 <= 1'b0;
        end else begin
            counter_comb_buf1 <= counter_comb;
            clk_out_comb_buf1 <= clk_out_comb;
            clk_out_reg_buf1 <= clk_out_reg;
        end
    end

    // Buffer stage 2: Further balance load for high fanout signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_comb_buf2 <= {WIDTH{1'b0}};
            clk_out_comb_buf2 <= 1'b0;
            clk_out_reg_buf2 <= 1'b0;
        end else begin
            counter_comb_buf2 <= counter_comb_buf1;
            clk_out_comb_buf2 <= clk_out_comb_buf1;
            clk_out_reg_buf2 <= clk_out_reg_buf1;
        end
    end

    // Main registers updated from buffered signals
    always @(posedge clk_in or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= {WIDTH{1'b0}};
            clk_out_reg <= 1'b0;
        end else begin
            counter_reg <= counter_comb_buf2;
            clk_out_reg <= clk_out_comb_buf2;
        end
    end

    // Output assignment using buffered clk_out_reg
    always @(*) begin
        clk_out = clk_out_reg_buf2;
    end

endmodule