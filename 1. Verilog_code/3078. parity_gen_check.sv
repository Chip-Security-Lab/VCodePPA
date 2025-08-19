module parity_gen_check(
    input wire clk, rst_n,
    input wire [7:0] data_in,
    input wire data_valid,
    input wire parity_type, // 0:even, 1:odd
    input wire gen_check_n, // 0:check, 1:generate
    output reg parity_bit,
    output reg error
);
    localparam IDLE=2'b00, COMPUTE=2'b01, OUTPUT=2'b10, ERROR_STATE=2'b11;
    reg [1:0] state, next;
    reg [7:0] data_reg;
    reg computed_parity;
    
    always @(posedge clk or negedge rst_n)
        if (!rst_n) begin
            state <= IDLE;
            data_reg <= 8'd0;
            parity_bit <= 1'b0;
            error <= 1'b0;
            computed_parity <= 1'b0;
        end else begin
            state <= next;
            
            case (state)
                IDLE: begin
                    error <= 1'b0;
                    if (data_valid)
                        data_reg <= data_in;
                end
                COMPUTE: begin
                    // Calculate parity
                    computed_parity <= ^data_reg ^ parity_type;
                    
                    if (gen_check_n) // Generate mode
                        parity_bit <= ^data_reg ^ parity_type;
                end
                OUTPUT: begin
                    if (!gen_check_n) // Check mode
                        error <= (computed_parity != parity_bit);
                end
                ERROR_STATE: error <= 1'b1;
            endcase
        end
    
    always @(*)
        case (state)
            IDLE: next = data_valid ? COMPUTE : IDLE;
            COMPUTE: next = OUTPUT;
            OUTPUT: next = (!gen_check_n && (computed_parity != parity_bit)) ? 
                          ERROR_STATE : IDLE;
            ERROR_STATE: next = IDLE;
            default: next = IDLE;
        endcase
endmodule