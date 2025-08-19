//SystemVerilog
module shadow_regfile #(
    parameter WIDTH = 8,
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

    reg [WIDTH-1:0] main_regs [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs [0:REG_COUNT-1];
    reg [WIDTH-1:0] temp_regs [0:REG_COUNT-1];

    function [WIDTH-1:0] han_carlson_adder;
        input [WIDTH-1:0] a, b;
        reg [WIDTH:0] sum;
        begin
            sum = a + b;
            han_carlson_adder = sum[WIDTH-1:0];
        end
    endfunction

    assign read_data = use_shadow ? shadow_regs[read_addr] : main_regs[read_addr];
    assign shadow_data = shadow_regs[read_addr];

    // Reset logic
    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (int i = 0; i < REG_COUNT; i++) begin
                main_regs[i] <= {WIDTH{1'b0}};
                shadow_regs[i] <= {WIDTH{1'b0}};
            end
        end
    end

    // Main register write
    always @(posedge clock) begin
        if (write_en) begin
            main_regs[write_addr] <= write_data;
        end
    end

    // Shadow load operation
    always @(posedge clock) begin
        if (shadow_load) begin
            for (int i = 0; i < REG_COUNT; i++) begin
                shadow_regs[i] <= han_carlson_adder(main_regs[i], 0);
            end
        end
    end

    // Shadow swap operation
    always @(posedge clock) begin
        if (shadow_swap) begin
            for (int i = 0; i < REG_COUNT; i++) begin
                temp_regs[i] <= main_regs[i];
                main_regs[i] <= shadow_regs[i];
                shadow_regs[i] <= temp_regs[i];
            end
        end
    end

endmodule