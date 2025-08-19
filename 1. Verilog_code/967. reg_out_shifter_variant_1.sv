//SystemVerilog
module reg_out_shifter (
    input clk,
    input reset_n,
    input valid,
    output ready,
    input [3:0] data_in,
    output reg [3:0] data_out,
    output reg data_valid
);

    reg [3:0] shift_reg;
    reg ready_reg;
    reg [1:0] state;
    reg [3:0] data_in_reg;
    reg valid_reg;
    
    localparam IDLE = 2'b00;
    localparam SHIFT = 2'b01;
    localparam OUTPUT = 2'b10;

    assign ready = ready_reg;

    always @(posedge clk or negedge reset_n) begin
        if (!reset_n) begin
            shift_reg <= 4'b0000;
            data_out <= 4'b0000;
            data_valid <= 1'b0;
            ready_reg <= 1'b1;
            state <= IDLE;
            data_in_reg <= 4'b0000;
            valid_reg <= 1'b0;
        end
        else begin
            data_in_reg <= data_in;
            valid_reg <= valid;
            
            case (state)
                IDLE: begin
                    if (valid_reg && ready_reg) begin
                        shift_reg <= data_in_reg;
                        ready_reg <= 1'b0;
                        state <= SHIFT;
                    end
                end
                SHIFT: begin
                    shift_reg <= {1'b0, shift_reg[3:1]};
                    if (shift_reg == 4'b0000) begin
                        state <= OUTPUT;
                    end
                end
                OUTPUT: begin
                    data_out <= shift_reg;
                    data_valid <= 1'b1;
                    ready_reg <= 1'b1;
                    state <= IDLE;
                end
            endcase
        end
    end
endmodule