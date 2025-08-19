//SystemVerilog
module basic_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,
    input  wire                   we,
    input  wire [ADDR_WIDTH-1:0]  addr,
    input  wire [DATA_WIDTH-1:0]  wdata,
    output wire [DATA_WIDTH-1:0]  rdata
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DATA_WIDTH-1:0] mem_buf [0:DEPTH-1];
    reg [ADDR_WIDTH-1:0] addr_buf;
    reg we_buf;
    
    // Optimized read path with direct memory access
    assign rdata = mem[addr];
    
    // Optimized write and buffer update logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            // Reset logic with parallel assignment
            for (int i = 0; i < DEPTH; i++) begin
                mem[i] <= '0;
                mem_buf[i] <= '0;
            end
            addr_buf <= '0;
            we_buf <= 1'b0;
        end 
        else begin
            // Buffer control signals with reduced fanout
            addr_buf <= addr;
            we_buf <= we;
            
            // Optimized write operation with conditional update
            if (we) begin
                mem[addr] <= wdata;
                mem_buf[addr] <= wdata;
            end
            else begin
                mem_buf[addr] <= mem[addr];
            end
        end
    end
endmodule