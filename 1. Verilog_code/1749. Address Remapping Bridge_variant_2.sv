//SystemVerilog
module remap_bridge #(parameter DWIDTH=32, AWIDTH=32) (
    input clk, rst_n,
    input [AWIDTH-1:0] in_addr,
    input [DWIDTH-1:0] in_data,
    input in_valid, in_write,
    output reg in_ready,
    output reg [AWIDTH-1:0] out_addr,
    output reg [DWIDTH-1:0] out_data,
    output reg out_valid, out_write,
    input out_ready
);

    parameter [AWIDTH-1:0] REMAP_BASE0 = 32'h1000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE0 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST0 = 32'h2000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE1 = 32'h2000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE1 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST1 = 32'h3000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE2 = 32'h3000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE2 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST2 = 32'h4000_0000;
    
    parameter [AWIDTH-1:0] REMAP_BASE3 = 32'h4000_0000;
    parameter [AWIDTH-1:0] REMAP_SIZE3 = 32'h0001_0000;
    parameter [AWIDTH-1:0] REMAP_DEST3 = 32'h5000_0000;
    
    parameter [AWIDTH-1:0] REMAP_LIMIT0 = REMAP_BASE0 + REMAP_SIZE0;
    parameter [AWIDTH-1:0] REMAP_LIMIT1 = REMAP_BASE1 + REMAP_SIZE1;
    parameter [AWIDTH-1:0] REMAP_LIMIT2 = REMAP_BASE2 + REMAP_SIZE2;
    parameter [AWIDTH-1:0] REMAP_LIMIT3 = REMAP_BASE3 + REMAP_SIZE3;
    
    reg [AWIDTH-1:0] in_addr_reg;
    reg [DWIDTH-1:0] in_data_reg;
    reg in_valid_reg, in_write_reg;
    reg [3:0] region_match_reg;
    reg [AWIDTH-1:0] offset_addr_reg;
    reg [AWIDTH-1:0] remapped_addr_reg;
    
    wire [3:0] region_match;
    wire [AWIDTH-1:0] offset_addr;
    wire [AWIDTH-1:0] remapped_addr;
    
    assign region_match[0] = (in_addr_reg >= REMAP_BASE0) && (in_addr_reg < REMAP_LIMIT0);
    assign region_match[1] = (in_addr_reg >= REMAP_BASE1) && (in_addr_reg < REMAP_LIMIT1);
    assign region_match[2] = (in_addr_reg >= REMAP_BASE2) && (in_addr_reg < REMAP_LIMIT2);
    assign region_match[3] = (in_addr_reg >= REMAP_BASE3) && (in_addr_reg < REMAP_LIMIT3);
    
    assign offset_addr = 
        ({AWIDTH{region_match[0]}} & (in_addr_reg - REMAP_BASE0)) |
        ({AWIDTH{region_match[1]}} & (in_addr_reg - REMAP_BASE1)) |
        ({AWIDTH{region_match[2]}} & (in_addr_reg - REMAP_BASE2)) |
        ({AWIDTH{region_match[3]}} & (in_addr_reg - REMAP_BASE3));
    
    assign remapped_addr = 
        (|region_match) ? (
            ({AWIDTH{region_match[0]}} & REMAP_DEST0) |
            ({AWIDTH{region_match[1]}} & REMAP_DEST1) |
            ({AWIDTH{region_match[2]}} & REMAP_DEST2) |
            ({AWIDTH{region_match[3]}} & REMAP_DEST3)
        ) + offset_addr : in_addr_reg;
    
    localparam IDLE = 1'b0;
    localparam BUSY = 1'b1;
    reg state;
    
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in_addr_reg <= {AWIDTH{1'b0}};
            in_data_reg <= {DWIDTH{1'b0}};
            in_valid_reg <= 1'b0;
            in_write_reg <= 1'b0;
            region_match_reg <= 4'b0;
            offset_addr_reg <= {AWIDTH{1'b0}};
            remapped_addr_reg <= {AWIDTH{1'b0}};
            out_valid <= 1'b0;
            in_ready <= 1'b1;
            out_addr <= {AWIDTH{1'b0}};
            out_data <= {DWIDTH{1'b0}};
            out_write <= 1'b0;
            state <= IDLE;
        end else begin
            in_addr_reg <= in_addr;
            in_data_reg <= in_data;
            in_valid_reg <= in_valid;
            in_write_reg <= in_write;
            region_match_reg <= region_match;
            offset_addr_reg <= offset_addr;
            remapped_addr_reg <= remapped_addr;
            
            case (state)
                IDLE: begin
                    if (in_valid_reg) begin
                        out_data <= in_data_reg;
                        out_write <= in_write_reg;
                        out_valid <= 1'b1;
                        in_ready <= 1'b0;
                        out_addr <= remapped_addr_reg;
                        state <= BUSY;
                    end
                end
                
                BUSY: begin
                    if (out_ready) begin
                        out_valid <= 1'b0;
                        in_ready <= 1'b1;
                        state <= IDLE;
                    end
                end
            endcase
        end
    end
endmodule