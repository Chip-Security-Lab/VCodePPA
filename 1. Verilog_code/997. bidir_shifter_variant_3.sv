//SystemVerilog
module bidir_shifter(
    input        clk,
    input        reset_n,
    input  [7:0] data_in,
    input  [2:0] shift_amount,
    input        left_right_n,    // 1=left, 0=right
    input        arithmetic_n,    // 1=arithmetic, 0=logical (right only)
    output [7:0] data_out
);
    reg [7:0] data_in_reg;
    reg [2:0] shift_amount_reg;
    reg       left_right_n_reg;
    reg       arithmetic_n_reg;
    reg [7:0] data_out_comb;
    reg [7:0] data_out_reg;

    // Input registers
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            data_in_reg        <= 8'h00;
            shift_amount_reg   <= 3'b000;
            left_right_n_reg   <= 1'b0;
            arithmetic_n_reg   <= 1'b0;
        end else begin
            data_in_reg        <= data_in;
            shift_amount_reg   <= shift_amount;
            left_right_n_reg   <= left_right_n;
            arithmetic_n_reg   <= arithmetic_n;
        end
    end

    // Combinational shift logic with case statement
    always @(*) begin
        case ({left_right_n_reg, arithmetic_n_reg, data_in_reg[7]})
            3'b100, 3'b101, 3'b110, 3'b111: begin // left shift
                data_out_comb = data_in_reg << shift_amount_reg;
            end
            3'b010: begin // right logical shift
                data_out_comb = data_in_reg >> shift_amount_reg;
            end
            3'b011: begin // right arithmetic shift, MSB=1
                data_out_comb = (data_in_reg >> shift_amount_reg) | (~({8{1'b1}} >> shift_amount_reg));
            end
            3'b000, 3'b001: begin // right logical shift, MSB=0
                data_out_comb = data_in_reg >> shift_amount_reg;
            end
            default: begin
                data_out_comb = data_in_reg >> shift_amount_reg;
            end
        endcase
    end

    // Output register
    always @(posedge clk or negedge reset_n) begin
        if (!reset_n)
            data_out_reg <= 8'h00;
        else
            data_out_reg <= data_out_comb;
    end

    assign data_out = data_out_reg;
endmodule