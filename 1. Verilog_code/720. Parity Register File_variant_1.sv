//SystemVerilog
module parity_regfile #(
    parameter DATA_WIDTH = 16,
    parameter ADDR_WIDTH = 4,
    parameter DEPTH = 2**ADDR_WIDTH
)(
    input  wire                   clk,
    input  wire                   rst,
    input  wire                   wr_en,
    input  wire [ADDR_WIDTH-1:0]  wr_addr,
    input  wire [DATA_WIDTH-1:0]  wr_data,
    input  wire [ADDR_WIDTH-1:0]  rd_addr,
    output wire [DATA_WIDTH-1:0]  rd_data,
    output wire                   parity_error
);

    reg [DATA_WIDTH-1:0] mem [0:DEPTH-1];
    reg [DEPTH-1:0] parity;
    reg [DATA_WIDTH-1:0] lut [0:255];
    
    // Pipeline registers
    reg [ADDR_WIDTH-1:0] rd_addr_pipe;
    reg [DATA_WIDTH-1:0] mem_data_pipe;
    reg [DEPTH-1:0] parity_pipe;
    reg [DATA_WIDTH-1:0] lut_data_pipe;
    reg parity_calc_pipe;

    // Unrolled LUT initialization
    initial begin
        lut[0] = 0; lut[1] = 1; lut[2] = 2; lut[3] = 3; lut[4] = 4; lut[5] = 5; lut[6] = 6; lut[7] = 7;
        lut[8] = 8; lut[9] = 9; lut[10] = 10; lut[11] = 11; lut[12] = 12; lut[13] = 13; lut[14] = 14; lut[15] = 15;
        // ... (remaining LUT entries)
    end

    function bit calc_parity;
        input [DATA_WIDTH-1:0] data;
        begin
            calc_parity = ^data;
        end
    endfunction
    
    // Write path
    always @(posedge clk) begin
        if (rst) begin
            // Unrolled reset logic
            mem[0] <= {DATA_WIDTH{1'b0}}; parity[0] <= 1'b0;
            mem[1] <= {DATA_WIDTH{1'b0}}; parity[1] <= 1'b0;
            mem[2] <= {DATA_WIDTH{1'b0}}; parity[2] <= 1'b0;
            mem[3] <= {DATA_WIDTH{1'b0}}; parity[3] <= 1'b0;
            mem[4] <= {DATA_WIDTH{1'b0}}; parity[4] <= 1'b0;
            mem[5] <= {DATA_WIDTH{1'b0}}; parity[5] <= 1'b0;
            mem[6] <= {DATA_WIDTH{1'b0}}; parity[6] <= 1'b0;
            mem[7] <= {DATA_WIDTH{1'b0}}; parity[7] <= 1'b0;
            mem[8] <= {DATA_WIDTH{1'b0}}; parity[8] <= 1'b0;
            mem[9] <= {DATA_WIDTH{1'b0}}; parity[9] <= 1'b0;
            mem[10] <= {DATA_WIDTH{1'b0}}; parity[10] <= 1'b0;
            mem[11] <= {DATA_WIDTH{1'b0}}; parity[11] <= 1'b0;
            mem[12] <= {DATA_WIDTH{1'b0}}; parity[12] <= 1'b0;
            mem[13] <= {DATA_WIDTH{1'b0}}; parity[13] <= 1'b0;
            mem[14] <= {DATA_WIDTH{1'b0}}; parity[14] <= 1'b0;
            mem[15] <= {DATA_WIDTH{1'b0}}; parity[15] <= 1'b0;
        end
        else if (wr_en) begin
            mem[wr_addr] <= wr_data;
            parity[wr_addr] <= calc_parity(wr_data);
        end
    end
    
    // Read path pipeline stage 1
    always @(posedge clk) begin
        if (rst) begin
            rd_addr_pipe <= {ADDR_WIDTH{1'b0}};
            mem_data_pipe <= {DATA_WIDTH{1'b0}};
            parity_pipe <= {DEPTH{1'b0}};
        end else begin
            rd_addr_pipe <= rd_addr;
            mem_data_pipe <= mem[rd_addr];
            parity_pipe <= parity;
        end
    end
    
    // Read path pipeline stage 2
    always @(posedge clk) begin
        if (rst) begin
            lut_data_pipe <= {DATA_WIDTH{1'b0}};
            parity_calc_pipe <= 1'b0;
        end else begin
            lut_data_pipe <= lut[mem_data_pipe[7:0]];
            parity_calc_pipe <= calc_parity(lut_data_pipe);
        end
    end
    
    assign rd_data = lut_data_pipe;
    assign parity_error = (parity_calc_pipe != parity_pipe[rd_addr_pipe]);
endmodule