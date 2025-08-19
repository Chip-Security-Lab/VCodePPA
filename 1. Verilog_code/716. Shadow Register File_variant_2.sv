//SystemVerilog
// Main register file module
module main_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 4,
    parameter REG_COUNT = 2**ADDR_BITS
)(
    input  wire                 clock,
    input  wire                 resetn,
    input  wire                 write_en,
    input  wire [ADDR_BITS-1:0] write_addr,
    input  wire [WIDTH-1:0]     write_data,
    input  wire [ADDR_BITS-1:0] read_addr,
    output wire [WIDTH-1:0]     read_data
);
    reg [WIDTH-1:0] regs [0:REG_COUNT-1];
    
    assign read_data = regs[read_addr];
    
    integer i;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                regs[i] <= {WIDTH{1'b0}};
            end
        end
    end

    always @(posedge clock) begin
        if (write_en) begin
            regs[write_addr] <= write_data;
        end
    end
endmodule

// Shadow register file module
module shadow_regfile_core #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 4,
    parameter REG_COUNT = 2**ADDR_BITS
)(
    input  wire                 clock,
    input  wire                 resetn,
    input  wire [ADDR_BITS-1:0] read_addr,
    input  wire [WIDTH-1:0]     main_data [0:REG_COUNT-1],
    input  wire                 shadow_load,
    input  wire                 shadow_swap,
    output wire [WIDTH-1:0]     shadow_data,
    output reg  [WIDTH-1:0]     shadow_regs [0:REG_COUNT-1]
);
    assign shadow_data = shadow_regs[read_addr];
    
    integer i;
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                shadow_regs[i] <= {WIDTH{1'b0}};
            end
        end
    end

    always @(posedge clock) begin
        if (shadow_load) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                shadow_regs[i] <= main_data[i];
            end
        end
        else if (shadow_swap) begin
            for (i = 0; i < REG_COUNT; i = i + 1) begin
                shadow_regs[i] <= main_data[i];
            end
        end
    end
endmodule

// Top-level shadow register file module
module shadow_regfile #(
    parameter WIDTH = 32,
    parameter ADDR_BITS = 4,
    parameter REG_COUNT = 2**ADDR_BITS
)(
    input  wire                 clock,
    input  wire                 resetn,
    input  wire                 write_en,
    input  wire [ADDR_BITS-1:0] write_addr,
    input  wire [WIDTH-1:0]     write_data,
    input  wire [ADDR_BITS-1:0] read_addr,
    output wire [WIDTH-1:0]     read_data,
    input  wire                 shadow_load,
    input  wire                 shadow_swap,
    input  wire                 use_shadow,
    output wire [WIDTH-1:0]     shadow_data
);
    wire [WIDTH-1:0] main_data [0:REG_COUNT-1];
    wire [WIDTH-1:0] shadow_regs [0:REG_COUNT-1];
    
    main_regfile #(
        .WIDTH(WIDTH),
        .ADDR_BITS(ADDR_BITS),
        .REG_COUNT(REG_COUNT)
    ) main_regs (
        .clock(clock),
        .resetn(resetn),
        .write_en(write_en),
        .write_addr(write_addr),
        .write_data(write_data),
        .read_addr(read_addr),
        .read_data(read_data)
    );
    
    shadow_regfile_core #(
        .WIDTH(WIDTH),
        .ADDR_BITS(ADDR_BITS),
        .REG_COUNT(REG_COUNT)
    ) shadow_regs_inst (
        .clock(clock),
        .resetn(resetn),
        .read_addr(read_addr),
        .main_data(main_data),
        .shadow_load(shadow_load),
        .shadow_swap(shadow_swap),
        .shadow_data(shadow_data),
        .shadow_regs(shadow_regs)
    );
    
    assign read_data = use_shadow ? shadow_regs[read_addr] : main_data[read_addr];
endmodule