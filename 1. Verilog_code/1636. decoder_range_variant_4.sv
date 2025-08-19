//SystemVerilog
// Address register module
module addr_reg #(
    parameter WIDTH = 8
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] addr_in,
    output reg  [WIDTH-1:0] addr_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            addr_out <= {WIDTH{1'b0}};
        end else begin
            addr_out <= addr_in;
        end
    end

endmodule

// Range comparison module with optimized logic
module range_compare #(
    parameter WIDTH = 8,
    parameter MIN = 8'h20,
    parameter MAX = 8'h3F
) (
    input  wire             clk,
    input  wire             rst_n,
    input  wire [WIDTH-1:0] addr_in,
    output reg              in_range
);

    wire [WIDTH-1:0] min_val = MIN;
    wire [WIDTH-1:0] max_val = MAX;
    wire            ge_min;
    wire            le_max;

    // Split comparison logic to reduce critical path
    assign ge_min = (addr_in >= min_val);
    assign le_max = (addr_in <= max_val);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_range <= 1'b0;
        end else begin
            in_range <= ge_min & le_max;
        end
    end

endmodule

// Output register module
module out_reg (
    input  wire clk,
    input  wire rst_n,
    input  wire data_in,
    output reg  data_out
);

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_out <= 1'b0;
        end else begin
            data_out <= data_in;
        end
    end

endmodule

// Top-level decoder module with optimized structure
module decoder_range #(
    parameter MIN = 8'h20,
    parameter MAX = 8'h3F
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire [7:0] addr_in,
    output wire       active_out
);

    wire [7:0] addr_reg_out;
    wire       range_out;

    addr_reg #(
        .WIDTH(8)
    ) u_addr_reg (
        .clk     (clk),
        .rst_n   (rst_n),
        .addr_in (addr_in),
        .addr_out(addr_reg_out)
    );

    range_compare #(
        .WIDTH(8),
        .MIN(MIN),
        .MAX(MAX)
    ) u_range_compare (
        .clk     (clk),
        .rst_n   (rst_n),
        .addr_in (addr_reg_out),
        .in_range(range_out)
    );

    out_reg u_out_reg (
        .clk     (clk),
        .rst_n   (rst_n),
        .data_in (range_out),
        .data_out(active_out)
    );

endmodule