//SystemVerilog
module forwarding_regfile #(
    parameter DATA_WIDTH = 32,
    parameter REG_COUNT = 32,
    parameter ADDR_WIDTH = $clog2(REG_COUNT),
    parameter READ_PORTS = 2
)(
    input  wire                   clk,
    input  wire                   rst,
    
    // Write port
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    
    // Read ports
    input  wire [ADDR_WIDTH-1:0]  rd_addr1,
    output wire [DATA_WIDTH-1:0]  rd_data1,
    input  wire [ADDR_WIDTH-1:0]  rd_addr2,
    output wire [DATA_WIDTH-1:0]  rd_data2
);
    // Register file
    reg [DATA_WIDTH-1:0] regs [0:REG_COUNT-1];
    
    // Instantiate read port modules
    read_port #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_port_1 (
        .rd_addr(rd_addr1),
        .reg_data(regs[rd_addr1]),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_data(rd_data1)
    );
    
    read_port #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) read_port_2 (
        .rd_addr(rd_addr2),
        .reg_data(regs[rd_addr2]),
        .wr_en(wr_en),
        .wr_addr(wr_addr),
        .wr_data(wr_data),
        .rd_data(rd_data2)
    );
    
    // Write operation with reset
    always @(posedge clk) begin
        if (rst) begin
            integer i;
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {DATA_WIDTH{1'b0}};
            end
        end
        else if (wr_en && (wr_addr != 0)) begin
            // Register 0 is hardwired to zero
            regs[wr_addr] <= wr_data;
        end
    end
endmodule

// Reusable read port module with forwarding logic
module read_port #(
    parameter DATA_WIDTH = 32,
    parameter ADDR_WIDTH = 5
)(
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    input  wire [DATA_WIDTH-1:0]  reg_data,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    output wire [DATA_WIDTH-1:0]  rd_data
);
    // Forwarding logic
    assign rd_data = (wr_en && (rd_addr == wr_addr) && (rd_addr != 0)) ? 
                     wr_data : reg_data;
endmodule