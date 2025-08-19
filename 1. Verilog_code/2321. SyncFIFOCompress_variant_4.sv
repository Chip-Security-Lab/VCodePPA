//SystemVerilog
module SyncFIFOCompress #(
    parameter DW = 8,   // Data width
    parameter AW = 12   // Address width
) (
    input  wire         clk,      // Clock signal
    input  wire         rst_n,    // Active-low reset
    input  wire         wr_en,    // Write enable
    input  wire         rd_en,    // Read enable
    input  wire [DW-1:0] din,     // Data input
    output wire [DW-1:0] dout,    // Data output
    output wire          full,    // FIFO full indicator
    output wire          empty    // FIFO empty indicator
);

    // Internal signals
    wire [AW:0] wr_ptr, rd_ptr;
    wire [DW-1:0] mem_rd_data;
    wire mem_wr_en;
    
    // Control logic submodule
    FifoControlLogic #(
        .AW(AW)
    ) control_logic_inst (
        .clk(clk),
        .rst_n(rst_n),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .full(full),
        .empty(empty),
        .wr_ptr(wr_ptr),
        .rd_ptr(rd_ptr),
        .mem_wr_en(mem_wr_en)
    );
    
    // Memory submodule
    FifoMemory #(
        .DW(DW),
        .AW(AW)
    ) memory_inst (
        .clk(clk),
        .mem_wr_en(mem_wr_en),
        .wr_addr(wr_ptr[AW-1:0]),
        .rd_addr(rd_ptr[AW-1:0]),
        .din(din),
        .dout(mem_rd_data)
    );
    
    // Output register submodule
    FifoOutputReg #(
        .DW(DW)
    ) output_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .rd_en(rd_en),
        .empty(empty),
        .mem_rd_data(mem_rd_data),
        .dout(dout)
    );

endmodule

module FifoControlLogic #(
    parameter AW = 12   // Address width
) (
    input  wire       clk,
    input  wire       rst_n,
    input  wire       wr_en,
    input  wire       rd_en,
    output wire       full,
    output wire       empty,
    output reg [AW:0] wr_ptr,
    output reg [AW:0] rd_ptr,
    output wire       mem_wr_en
);

    // Status signals generation
    assign full = (wr_ptr - rd_ptr) == (1<<AW);
    assign empty = (wr_ptr == rd_ptr);
    
    // Memory write enable gating
    assign mem_wr_en = wr_en && !full;

    // Pointer management
    always @(posedge clk) begin
        if (!rst_n) begin
            // Reset condition
            wr_ptr <= {(AW+1){1'b0}};
            rd_ptr <= {(AW+1){1'b0}};
        end else begin
            // Write pointer update
            if (wr_en && !full) begin
                wr_ptr <= wr_ptr + 1'b1;
            end
            
            // Read pointer update
            if (rd_en && !empty) begin
                rd_ptr <= rd_ptr + 1'b1;
            end
        end
    end

endmodule

module FifoMemory #(
    parameter DW = 8,   // Data width
    parameter AW = 12   // Address width
) (
    input  wire         clk,
    input  wire         mem_wr_en,
    input  wire [AW-1:0] wr_addr,
    input  wire [AW-1:0] rd_addr,
    input  wire [DW-1:0] din,
    output wire [DW-1:0] dout
);

    // Memory declaration
    reg [DW-1:0] mem [0:(1<<AW)-1];
    
    // Memory write operation
    always @(posedge clk) begin
        if (mem_wr_en) begin
            mem[wr_addr] <= din;
        end
    end
    
    // Memory read operation (asynchronous read)
    assign dout = mem[rd_addr];

endmodule

module FifoOutputReg #(
    parameter DW = 8   // Data width
) (
    input  wire         clk,
    input  wire         rst_n,
    input  wire         rd_en,
    input  wire         empty,
    input  wire [DW-1:0] mem_rd_data,
    output reg  [DW-1:0] dout
);

    // Output register update
    always @(posedge clk) begin
        if (!rst_n) begin
            dout <= {DW{1'b0}};
        end else if (rd_en && !empty) begin
            dout <= mem_rd_data;
        end
    end

endmodule