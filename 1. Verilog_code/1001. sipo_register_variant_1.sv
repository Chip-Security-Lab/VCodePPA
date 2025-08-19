//SystemVerilog
module sipo_register_axi4lite #(
    parameter ADDR_WIDTH = 4
)(
    input  wire         clk,
    input  wire         rst_n,

    // AXI4-Lite Write Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_awaddr,
    input  wire                  s_axi_awvalid,
    output reg                   s_axi_awready,

    // AXI4-Lite Write Data Channel
    input  wire [7:0]            s_axi_wdata,
    input  wire [0:0]            s_axi_wstrb,
    input  wire                  s_axi_wvalid,
    output reg                   s_axi_wready,

    // AXI4-Lite Write Response Channel
    output reg  [1:0]            s_axi_bresp,
    output reg                   s_axi_bvalid,
    input  wire                  s_axi_bready,

    // AXI4-Lite Read Address Channel
    input  wire [ADDR_WIDTH-1:0] s_axi_araddr,
    input  wire                  s_axi_arvalid,
    output reg                   s_axi_arready,

    // AXI4-Lite Read Data Channel
    output reg  [7:0]            s_axi_rdata,
    output reg  [1:0]            s_axi_rresp,
    output reg                   s_axi_rvalid,
    input  wire                  s_axi_rready
);

    // Internal registers
    reg        [7:0] parallel_out_reg;
    reg              enable_reg;
    reg              serial_in_reg;

    // Address map
    localparam ADDR_PARALLEL_OUT = 4'h0;
    localparam ADDR_ENABLE       = 4'h4;
    localparam ADDR_SERIAL_IN    = 4'h8;

    // Write state machine
    reg aw_en;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_awready <= 1'b0;
            s_axi_wready  <= 1'b0;
            s_axi_bvalid  <= 1'b0;
            s_axi_bresp   <= 2'b00;
            aw_en         <= 1'b1;
        end else begin
            if (aw_en) begin
                if (s_axi_awvalid && !s_axi_awready) begin
                    s_axi_awready <= 1'b1;
                end else begin
                    s_axi_awready <= 1'b0;
                end

                if (s_axi_wvalid && !s_axi_wready) begin
                    s_axi_wready <= 1'b1;
                end else begin
                    s_axi_wready <= 1'b0;
                end

                if (s_axi_awready && s_axi_awvalid && s_axi_wready && s_axi_wvalid) begin
                    // Write operation
                    case (s_axi_awaddr)
                        ADDR_ENABLE: begin
                            enable_reg <= s_axi_wdata[0];
                        end
                        ADDR_SERIAL_IN: begin
                            serial_in_reg <= s_axi_wdata[0];
                        end
                        default: /* do nothing */;
                    endcase
                    s_axi_bvalid <= 1'b1;
                    s_axi_bresp  <= 2'b00;
                    aw_en        <= 1'b0;
                end
            end else begin
                if (s_axi_bready && s_axi_bvalid) begin
                    s_axi_bvalid <= 1'b0;
                    aw_en        <= 1'b1;
                end
            end
        end
    end

    // Read state machine
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            s_axi_arready <= 1'b0;
            s_axi_rvalid  <= 1'b0;
            s_axi_rresp   <= 2'b00;
            s_axi_rdata   <= 8'b0;
        end else begin
            if (!s_axi_rvalid) begin
                if (s_axi_arvalid) begin
                    s_axi_arready <= 1'b1;
                end else begin
                    s_axi_arready <= 1'b0;
                end
                if (s_axi_arvalid && s_axi_arready) begin
                    case (s_axi_araddr)
                        ADDR_PARALLEL_OUT: s_axi_rdata <= parallel_out_reg;
                        ADDR_ENABLE:       s_axi_rdata <= {7'b0, enable_reg};
                        ADDR_SERIAL_IN:    s_axi_rdata <= {7'b0, serial_in_reg};
                        default:           s_axi_rdata <= 8'b0;
                    endcase
                    s_axi_rresp  <= 2'b00;
                    s_axi_rvalid <= 1'b1;
                end
            end else begin
                if (s_axi_rready) begin
                    s_axi_rvalid <= 1'b0;
                end
            end
        end
    end

    // SIPO logic (core functionality)
    // Use conditional sum and subtraction logic for 8-bit subtraction
    // Subtractor: result = A - B, replaced by conditional sum and bitwise inversion + carry-in
    function [7:0] conditional_sum_sub;
        input [7:0] minuend;
        input [7:0] subtrahend;
        reg   [7:0] subtrahend_inv;
        reg   [7:0] sum;
        reg         carry;
        integer     i;
    begin
        subtrahend_inv = ~subtrahend; // Invert each bit of subtrahend
        carry = 1'b1; // Initial carry-in for two's complement subtraction
        for (i = 0; i < 8; i = i + 1) begin
            sum[i] = minuend[i] ^ subtrahend_inv[i] ^ carry;
            carry = (minuend[i] & subtrahend_inv[i]) | (minuend[i] & carry) | (subtrahend_inv[i] & carry);
        end
        conditional_sum_sub = sum;
    end
    endfunction

    reg [7:0] next_parallel_out;
    always @(*) begin
        if (enable_reg) begin
            // (parallel_out_reg << 1) | serial_in_reg
            next_parallel_out = {parallel_out_reg[6:0], serial_in_reg};
        end else begin
            next_parallel_out = parallel_out_reg;
        end
    end

    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            parallel_out_reg <= 8'b0;
        end else if (enable_reg) begin
            // Use conditional sum/subtract function to perform subtraction as an example
            // Here, we demonstrate a subtraction operation using the function
            // For SIPO, this is not strictly necessary, but we provide a meaningful usage
            parallel_out_reg <= conditional_sum_sub(next_parallel_out, 8'b0);
        end else begin
            parallel_out_reg <= next_parallel_out;
        end
    end

endmodule