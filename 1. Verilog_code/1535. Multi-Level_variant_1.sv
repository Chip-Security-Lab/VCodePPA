//SystemVerilog
// IEEE 1364-2005 Verilog
module multi_shadow_reg #(
    parameter WIDTH = 8,
    parameter LEVELS = 3
)(
    input wire clk,
    input wire rst_n,
    input wire [WIDTH-1:0] data_in,
    input wire capture,
    input wire [1:0] shadow_select,
    output wire [WIDTH-1:0] shadow_out
);
    // Main register
    reg [WIDTH-1:0] main_reg;
    // Multiple shadow registers
    reg [WIDTH-1:0] shadow_reg [0:LEVELS-1];
    
    // Buffered signals for high fan-out reduction
    reg [1:0] shadow_select_buf1, shadow_select_buf2;
    reg capture_buf1, capture_buf2;
    
    // Main register update
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            main_reg <= 0;
        else
            main_reg <= data_in;
    end
    
    // Buffer registers for high fan-out signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            shadow_select_buf1 <= 0;
            shadow_select_buf2 <= 0;
            capture_buf1 <= 0;
            capture_buf2 <= 0;
        end else begin
            shadow_select_buf1 <= shadow_select;
            shadow_select_buf2 <= shadow_select_buf1;
            capture_buf1 <= capture;
            capture_buf2 <= capture_buf1;
        end
    end
    
    // Shadow registers update with case structure
    integer i;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < LEVELS; i = i + 1) begin
                shadow_reg[i] <= 0;
            end
        end else begin
            for (i = 0; i < LEVELS; i = i + 1) begin
                case (i)
                    0: begin
                        if (capture_buf1) shadow_reg[0] <= main_reg;
                    end
                    
                    LEVELS-1: begin
                        if (capture_buf2) shadow_reg[LEVELS-1] <= shadow_reg[LEVELS-2];
                    end
                    
                    default: begin
                        if (capture_buf1) shadow_reg[i] <= shadow_reg[i-1];
                    end
                endcase
            end
        end
    end
    
    // Output selection with buffered select signal and case structure
    reg [WIDTH-1:0] shadow_out_reg;
    always @(*) begin
        case (shadow_select_buf2)
            2'b00: shadow_out_reg = shadow_reg[0];
            2'b01: shadow_out_reg = shadow_reg[1];
            2'b10: shadow_out_reg = shadow_reg[2];
            2'b11: shadow_out_reg = (LEVELS > 3) ? shadow_reg[3] : shadow_reg[LEVELS-1];
            default: shadow_out_reg = shadow_reg[0];
        endcase
    end
    
    assign shadow_out = shadow_out_reg;
endmodule