//SystemVerilog
// Top-level module: Optimized pipelined byte/word/bit swapping shifter with reduced pipeline depth

module byte_swapping_shifter (
    input  wire         clk,
    input  wire         rst_n,
    input  wire [31:0]  data_in,
    input  wire [1:0]   swap_mode, // 00=none, 01=swap bytes, 10=swap words, 11=reverse
    output wire [31:0]  data_out
);

    // Pipeline Stage 1: Input Register and Swap Operations Combined
    reg  [31:0] data_stage1;
    reg  [1:0]  swap_mode_stage1;
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            data_stage1      <= 32'b0;
            swap_mode_stage1 <= 2'b0;
        end else begin
            case (swap_mode)
                2'b00: data_stage1 <= data_in;
                2'b01: data_stage1 <= {data_in[7:0], data_in[15:8], data_in[23:16], data_in[31:24]};
                2'b10: data_stage1 <= {data_in[15:0], data_in[31:16]};
                2'b11: data_stage1 <= bit_reverse_func(data_in);
                default: data_stage1 <= data_in;
            endcase
            swap_mode_stage1 <= swap_mode;
        end
    end

    assign data_out = data_stage1;

    // Bit Reverse Function (pure combinational, used in always block above)
    function [31:0] bit_reverse_func;
        input [31:0] din;
        integer i;
        begin
            for (i = 0; i < 32; i = i + 1)
                bit_reverse_func[i] = din[31 - i];
        end
    endfunction

endmodule