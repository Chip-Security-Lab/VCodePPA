//SystemVerilog
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
    
    // Read ports
    input  wire [ADDR_WIDTH-1:0]  read_addr1,
    output wire [DATA_WIDTH-1:0]  read_data1,
    input  wire [ADDR_WIDTH-1:0]  read_addr2,
    output wire [DATA_WIDTH-1:0]  read_data2,
    input  wire [ADDR_WIDTH-1:0]  read_addr3,
    output wire [DATA_WIDTH-1:0]  read_data3
);

    // Register file memory with byte enable
    reg [DATA_WIDTH-1:0] rf_mem [0:DEPTH-1];
    
    // Write bypass logic
    wire [DATA_WIDTH-1:0] write_data_muxed;
    wire [DATA_WIDTH-1:0] read_data1_bypass;
    wire [DATA_WIDTH-1:0] read_data2_bypass;
    wire [DATA_WIDTH-1:0] read_data3_bypass;
    
    // Write bypass conditions
    wire write_to_read1 = write_enable && (write_addr == read_addr1);
    wire write_to_read2 = write_enable && (write_addr == read_addr2);
    wire write_to_read3 = write_enable && (write_addr == read_addr3);
    
    // Memory read
    wire [DATA_WIDTH-1:0] mem_read_data1 = rf_mem[read_addr1];
    wire [DATA_WIDTH-1:0] mem_read_data2 = rf_mem[read_addr2];
    wire [DATA_WIDTH-1:0] mem_read_data3 = rf_mem[read_addr3];
    
    // Bypass muxes
    assign read_data1 = write_to_read1 ? write_data : mem_read_data1;
    assign read_data2 = write_to_read2 ? write_data : mem_read_data2;
    assign read_data3 = write_to_read3 ? write_data : mem_read_data3;
    
    // Sequential write logic with reset
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (integer i = 0; i < DEPTH; i = i + 1) begin
                rf_mem[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (write_enable) begin
            rf_mem[write_addr] <= write_data;
        end
    end

endmodule