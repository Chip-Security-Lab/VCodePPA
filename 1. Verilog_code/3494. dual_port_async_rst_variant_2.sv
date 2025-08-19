//SystemVerilog
//IEEE 1364-2005 Verilog standard
module dual_port_async_rst #(
    parameter ADDR_WIDTH = 4,
    parameter DATA_WIDTH = 8
)(
    input  wire                    clk,
    input  wire                    rst,
    input  wire                    wr_en,
    input  wire [ADDR_WIDTH-1:0]   addr_wr,
    input  wire [ADDR_WIDTH-1:0]   addr_rd,
    input  wire [DATA_WIDTH-1:0]   din,
    input  wire                    valid_in,
    output reg                     valid_out,
    output reg  [DATA_WIDTH-1:0]   dout
);

    // Memory definition - explicitly specify width first
    reg [DATA_WIDTH-1:0] mem [0:(1<<ADDR_WIDTH)-1];

    // Stage registers with more efficient naming scheme
    // Stage 1 - Input capture
    reg [ADDR_WIDTH-1:0] s1_addr_rd;
    reg [ADDR_WIDTH-1:0] s1_addr_wr;
    reg [DATA_WIDTH-1:0] s1_din;
    reg                  s1_wr_en;
    reg                  s1_valid;

    // Stage 2 - Memory read
    reg [DATA_WIDTH-1:0] s2_rdata;
    reg [ADDR_WIDTH-1:0] s2_addr_wr;
    reg [DATA_WIDTH-1:0] s2_din;
    reg                  s2_wr_en;
    reg                  s2_valid;

    // Stage 3 - Memory write and forward
    reg [DATA_WIDTH-1:0] s3_rdata;
    reg                  s3_valid;

    // Optimized logic for stage 1 - Input capture
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset all stage 1 registers in one block
            {s1_addr_rd, s1_addr_wr, s1_wr_en, s1_valid} <= {(2*ADDR_WIDTH+2){1'b0}};
            s1_din <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Register all inputs in parallel
            s1_addr_rd <= addr_rd;
            s1_addr_wr <= addr_wr;
            s1_din     <= din;
            s1_wr_en   <= wr_en;
            s1_valid   <= valid_in;
        end
    end

    // Optimized stage 2 - Memory read
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            // Reset stage 2 registers
            {s2_addr_wr, s2_wr_en, s2_valid} <= {(ADDR_WIDTH+2){1'b0}};
            s2_rdata <= {DATA_WIDTH{1'b0}};
            s2_din   <= {DATA_WIDTH{1'b0}};
        end
        else begin
            // Forward control signals
            s2_addr_wr <= s1_addr_wr;
            s2_din     <= s1_din;
            s2_wr_en   <= s1_wr_en;
            s2_valid   <= s1_valid;
            
            // Read operation - always executed regardless of valid
            s2_rdata   <= mem[s1_addr_rd];
        end
    end

    // Optimized stage 3 with write forwarding logic
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            s3_rdata <= {DATA_WIDTH{1'b0}};
            s3_valid <= 1'b0;
        end
        else begin
            // Memory write operation
            if (s2_wr_en) begin
                mem[s2_addr_wr] <= s2_din;
            end
            
            // Forward read data with improved naming
            s3_rdata <= s2_rdata;
            s3_valid <= s2_valid;
        end
    end

    // Output stage with non-blocking assignments
    always @(posedge clk or posedge rst) begin
        if (rst) begin
            dout <= {DATA_WIDTH{1'b0}};
            valid_out <= 1'b0;
        end
        else begin
            dout <= s3_rdata;
            valid_out <= s3_valid;
        end
    end

endmodule