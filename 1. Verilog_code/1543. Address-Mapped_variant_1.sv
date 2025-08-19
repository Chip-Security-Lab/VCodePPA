//SystemVerilog
// SystemVerilog
// IEEE 1364-2005 Verilog standard
module address_shadow_reg #(
    parameter WIDTH = 32,
    parameter ADDR_WIDTH = 4,
    parameter BASE_ADDR = 4'h0
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire [ADDR_WIDTH-1:0] addr,
    input wire write_en,
    input wire read_en,
    output reg [WIDTH-1:0] data_out,
    output reg [WIDTH-1:0] shadow_data
);
    // Pre-compute address comparisons to reduce critical path
    // Split complex address comparison into simpler logic
    wire base_addr_match = (addr[ADDR_WIDTH-1:1] == BASE_ADDR[ADDR_WIDTH-1:1]);
    wire lsb_match = (addr[0] == BASE_ADDR[0]);
    wire lsb_mismatch = (addr[0] != BASE_ADDR[0]);
    
    // Simplified address match logic using pre-computed values
    wire addr_match = base_addr_match && lsb_match;
    wire shadow_addr_match = base_addr_match && lsb_mismatch;
    
    // Register stage for input signals to improve timing
    reg [WIDTH-1:0] data_in_r;
    reg write_en_r;
    reg addr_match_r;
    reg shadow_addr_match_r;
    
    // Pipeline input signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_in_r <= {WIDTH{1'b0}};
            write_en_r <= 1'b0;
            addr_match_r <= 1'b0;
            shadow_addr_match_r <= 1'b0;
        end else begin
            data_in_r <= data_in;
            write_en_r <= write_en;
            addr_match_r <= addr_match;
            shadow_addr_match_r <= shadow_addr_match;
        end
    end
    
    // Simplified write conditions using registered signals
    wire write_to_main = write_en_r && addr_match_r;
    wire write_to_shadow = write_en_r && (shadow_addr_match_r || addr_match_r);
    
    // Register data_out with optimized control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            data_out <= {WIDTH{1'b0}};
        else if (write_to_main)
            data_out <= data_in_r;
    end
    
    // Register shadow_data with optimized control logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            shadow_data <= {WIDTH{1'b0}};
        else if (write_to_shadow)
            shadow_data <= data_in_r;
    end
    
endmodule