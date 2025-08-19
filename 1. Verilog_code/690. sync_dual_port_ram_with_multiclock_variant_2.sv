//SystemVerilog
module ram_core #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);

    (* ram_style = "block" *) reg [DATA_WIDTH-1:0] ram [(2**ADDR_WIDTH)-1:0];
    reg [DATA_WIDTH-1:0] sub_lut [0:255];
    reg [DATA_WIDTH-1:0] addr_a_reg, addr_b_reg;
    reg [DATA_WIDTH-1:0] din_a_reg, din_b_reg;
    reg we_a_reg, we_b_reg;
    
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end
    
    // Stage 1: Input registration
    always @(posedge clk_a) begin
        addr_a_reg <= addr_a;
        din_a_reg <= din_a;
        we_a_reg <= we_a;
    end
    
    always @(posedge clk_b) begin
        addr_b_reg <= addr_b;
        din_b_reg <= din_b;
        we_b_reg <= we_b;
    end
    
    // Stage 2: Write operation
    always @(posedge clk_a) begin
        if (we_a_reg) begin
            ram[addr_a_reg] <= sub_lut[din_a_reg];
        end
    end
    
    always @(posedge clk_b) begin
        if (we_b_reg) begin
            ram[addr_b_reg] <= sub_lut[din_b_reg];
        end
    end
    
    // Stage 3: Read operation
    reg [DATA_WIDTH-1:0] dout_a_reg, dout_b_reg;
    always @(posedge clk_a) begin
        dout_a_reg <= ram[addr_a_reg];
    end
    
    always @(posedge clk_b) begin
        dout_b_reg <= ram[addr_b_reg];
    end
    
    assign dout_a = dout_a_reg;
    assign dout_b = dout_b_reg;
    
endmodule

module port_a_control #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] sub_lut [0:255];
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [DATA_WIDTH-1:0] data_out_reg;
    
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_in_reg <= data_in;
        end
    end
    
    // Stage 2: LUT operation
    always @(posedge clk) begin
        if (rst) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out_reg <= sub_lut[data_in_reg];
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= data_out_reg;
        end
    end
    
endmodule

module port_b_control #(
    parameter DATA_WIDTH = 8
)(
    input wire clk,
    input wire rst,
    input wire [DATA_WIDTH-1:0] data_in,
    output reg [DATA_WIDTH-1:0] data_out
);

    reg [DATA_WIDTH-1:0] sub_lut [0:255];
    reg [DATA_WIDTH-1:0] data_in_reg;
    reg [DATA_WIDTH-1:0] data_out_reg;
    
    initial begin
        for (int i = 0; i < 256; i = i + 1) begin
            sub_lut[i] = i;
        end
    end

    // Stage 1: Input registration
    always @(posedge clk) begin
        if (rst) begin
            data_in_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_in_reg <= data_in;
        end
    end
    
    // Stage 2: LUT operation
    always @(posedge clk) begin
        if (rst) begin
            data_out_reg <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out_reg <= sub_lut[data_in_reg];
        end
    end
    
    // Stage 3: Output registration
    always @(posedge clk) begin
        if (rst) begin
            data_out <= {DATA_WIDTH{1'b0}};
        end else begin
            data_out <= data_out_reg;
        end
    end
    
endmodule

module sync_dual_port_ram_with_multiclock #(
    parameter DATA_WIDTH = 8,
    parameter ADDR_WIDTH = 8
)(
    input wire clk_a, clk_b,
    input wire rst_a, rst_b,
    input wire we_a, we_b,
    input wire [ADDR_WIDTH-1:0] addr_a, addr_b,
    input wire [DATA_WIDTH-1:0] din_a, din_b,
    output wire [DATA_WIDTH-1:0] dout_a, dout_b
);

    wire [DATA_WIDTH-1:0] ram_dout_a, ram_dout_b;
    
    ram_core #(
        .DATA_WIDTH(DATA_WIDTH),
        .ADDR_WIDTH(ADDR_WIDTH)
    ) ram_inst (
        .clk_a(clk_a),
        .clk_b(clk_b),
        .we_a(we_a),
        .we_b(we_b),
        .addr_a(addr_a),
        .addr_b(addr_b),
        .din_a(din_a),
        .din_b(din_b),
        .dout_a(ram_dout_a),
        .dout_b(ram_dout_b)
    );
    
    port_a_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) port_a_inst (
        .clk(clk_a),
        .rst(rst_a),
        .data_in(ram_dout_a),
        .data_out(dout_a)
    );
    
    port_b_control #(
        .DATA_WIDTH(DATA_WIDTH)
    ) port_b_inst (
        .clk(clk_b),
        .rst(rst_b),
        .data_in(ram_dout_b),
        .data_out(dout_b)
    );
    
endmodule