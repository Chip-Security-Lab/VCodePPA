//SystemVerilog
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

    reg [WIDTH-1:0] main_regs [0:REG_COUNT-1];
    reg [WIDTH-1:0] shadow_regs [0:REG_COUNT-1];
    reg [WIDTH-1:0] temp_regs [0:REG_COUNT-1];

    wire shadow_op = shadow_load | shadow_swap;
    wire [1:0] op_sel = {shadow_swap, shadow_load};

    assign read_data = use_shadow ? shadow_regs[read_addr] : main_regs[read_addr];
    assign shadow_data = shadow_regs[read_addr];

    always @(posedge clock or negedge resetn) begin
        if (!resetn) begin
            for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                main_regs[i] <= {WIDTH{1'b0}};
                shadow_regs[i] <= {WIDTH{1'b0}};
            end
        end
        else begin
            if (write_en) begin
                main_regs[write_addr] <= write_data;
            end
            
            if (shadow_op) begin
                case (op_sel)
                    2'b01: begin // Load shadow
                        for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                            shadow_regs[i] <= main_regs[i];
                        end
                    end
                    2'b10: begin // Swap
                        for (integer i = 0; i < REG_COUNT; i = i + 1) begin
                            temp_regs[i] <= main_regs[i];
                            main_regs[i] <= shadow_regs[i];
                            shadow_regs[i] <= temp_regs[i];
                        end
                    end
                endcase
            end
        end
    end

endmodule