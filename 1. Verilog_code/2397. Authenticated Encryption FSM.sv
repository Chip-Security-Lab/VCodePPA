module auth_encrypt_fsm #(parameter DATA_WIDTH = 16) (
    input wire clk, rst_l,
    input wire start, data_valid,
    input wire [DATA_WIDTH-1:0] data_in, key, nonce,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy, done, auth_ok
);
    // State encoding
    localparam IDLE = 3'b000;
    localparam INIT = 3'b001;
    localparam PROCESS = 3'b010;
    localparam FINALIZE = 3'b011;
    localparam VERIFY = 3'b100;
    localparam COMPLETE = 3'b101;
    
    reg [2:0] state, next_state;
    reg [DATA_WIDTH-1:0] running_auth;
    
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) state <= IDLE;
        else state <= next_state;
    end
    
    always @(*) begin
        next_state = state;
        case (state)
            IDLE: if (start) next_state = INIT;
            INIT: next_state = PROCESS;
            PROCESS: if (!data_valid) next_state = FINALIZE;
            FINALIZE: next_state = VERIFY;
            VERIFY: next_state = COMPLETE;
            COMPLETE: next_state = IDLE;
        endcase
    end
    
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            busy <= 0;
            done <= 0;
            auth_ok <= 0;
            running_auth <= 0;
        end else begin
            case (state)
                IDLE: begin
                    busy <= 0;
                    done <= 0;
                    if (start) busy <= 1;
                end
                INIT: running_auth <= nonce ^ key;
                PROCESS: if (data_valid) begin
                    data_out <= data_in ^ key;
                    running_auth <= running_auth ^ data_in;
                end
                VERIFY: auth_ok <= (running_auth == data_in);
                COMPLETE: begin
                    busy <= 0;
                    done <= 1;
                end
            endcase
        end
    end
endmodule