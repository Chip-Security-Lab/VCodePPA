module multi_port_regfile #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst_n,
    
    // Write port
    input  wire                   write_enable,
    input  wire [ADDR_WIDTH-1:0]  write_addr,
    input  wire [DATA_WIDTH-1:0]  write_data,
    
    // Read port 1
    input  wire [ADDR_WIDTH-1:0]  read_addr1,
    output wire [DATA_WIDTH-1:0]  read_data1,
    
    // Read port 2
    input  wire [ADDR_WIDTH-1:0]  read_addr2,
    output wire [DATA_WIDTH-1:0]  read_data2,
    
    // Read port 3
    input  wire [ADDR_WIDTH-1:0]  read_addr3,
    output wire [DATA_WIDTH-1:0]  read_data3
);
    // Register file memory
    reg [DATA_WIDTH-1:0] rf_mem [0:DEPTH-1];
    
    // Asynchronous reads
    assign read_data1 = rf_mem[read_addr1];
    assign read_data2 = rf_mem[read_addr2];
    assign read_data3 = rf_mem[read_addr3];
    
    // Synchronous write
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                rf_mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_enable) begin
            rf_mem[write_addr] <= write_data;
        end
    end
endmodule