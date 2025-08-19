//SystemVerilog
module priority_buf #(parameter DW=16) (
    input clk, rst_n,
    input [1:0] pri_level,
    input wr_en, rd_en,
    input [DW-1:0] din,
    output [DW-1:0] dout
);
    // Internal signals - wires for combinational logic outputs
    wire [DW-1:0] din_reg;
    wire [1:0] pri_level_reg;
    wire wr_en_reg;
    wire rd_en_reg;
    wire [1:0] next_rd_ptr;
    wire [DW-1:0] mem_read_data;
    wire [DW-1:0] dout_next;
    
    // Memory and registers
    reg [DW-1:0] mem[0:3];
    reg [1:0] rd_ptr;
    reg [DW-1:0] dout_reg;
    
    // Instantiate input register module
    input_registers #(.DW(DW)) input_reg_inst (
        .clk(clk),
        .rst_n(rst_n),
        .din(din),
        .pri_level(pri_level),
        .wr_en(wr_en),
        .rd_en(rd_en),
        .din_reg(din_reg),
        .pri_level_reg(pri_level_reg),
        .wr_en_reg(wr_en_reg),
        .rd_en_reg(rd_en_reg)
    );
    
    // Combinational logic module
    comb_logic #(.DW(DW)) comb_logic_inst (
        .rd_ptr(rd_ptr),
        .mem_0(mem[0]),
        .mem_1(mem[1]),
        .mem_2(mem[2]),
        .mem_3(mem[3]),
        .rd_en_reg(rd_en_reg),
        .next_rd_ptr(next_rd_ptr),
        .mem_read_data(mem_read_data),
        .dout_next(dout_next)
    );
    
    // Memory and read pointer sequential logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            mem[0] <= {DW{1'b0}};
            mem[1] <= {DW{1'b0}};
            mem[2] <= {DW{1'b0}};
            mem[3] <= {DW{1'b0}};
            rd_ptr <= 2'd0;
        end
        else begin
            if(wr_en_reg) 
                mem[pri_level_reg] <= din_reg;
                
            if(rd_en_reg)
                rd_ptr <= next_rd_ptr;
        end
    end
    
    // Output register sequential logic
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            dout_reg <= {DW{1'b0}};
        end
        else if(rd_en_reg) begin
            dout_reg <= mem_read_data;
        end
    end
    
    // Connect output register to module output
    assign dout = dout_reg;
    
endmodule

// Input registers module
module input_registers #(parameter DW=16) (
    input clk, rst_n,
    input [DW-1:0] din,
    input [1:0] pri_level,
    input wr_en, rd_en,
    output reg [DW-1:0] din_reg,
    output reg [1:0] pri_level_reg,
    output reg wr_en_reg,
    output reg rd_en_reg
);
    // Register inputs to reduce input-to-register delay
    always @(posedge clk or negedge rst_n) begin
        if(!rst_n) begin
            din_reg <= {DW{1'b0}};
            pri_level_reg <= 2'd0;
            wr_en_reg <= 1'b0;
            rd_en_reg <= 1'b0;
        end
        else begin
            din_reg <= din;
            pri_level_reg <= pri_level;
            wr_en_reg <= wr_en;
            rd_en_reg <= rd_en;
        end
    end
endmodule

// Combinational logic module
module comb_logic #(parameter DW=16) (
    input [1:0] rd_ptr,
    input [DW-1:0] mem_0,
    input [DW-1:0] mem_1,
    input [DW-1:0] mem_2,
    input [DW-1:0] mem_3,
    input rd_en_reg,
    output [1:0] next_rd_ptr,
    output [DW-1:0] mem_read_data,
    output [DW-1:0] dout_next
);
    // Next read pointer calculation
    assign next_rd_ptr = (rd_ptr == 2'd3) ? 2'd0 : rd_ptr + 2'd1;
    
    // Memory read data selection
    reg [DW-1:0] mem_read_data_reg;
    always @(*) begin
        case(rd_ptr)
            2'd0: mem_read_data_reg = mem_0;
            2'd1: mem_read_data_reg = mem_1;
            2'd2: mem_read_data_reg = mem_2;
            2'd3: mem_read_data_reg = mem_3;
            default: mem_read_data_reg = {DW{1'b0}};
        endcase
    end
    assign mem_read_data = mem_read_data_reg;
    
    // Next output data
    assign dout_next = rd_en_reg ? mem_read_data : {DW{1'b0}};
endmodule