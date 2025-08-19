//SystemVerilog IEEE 1364-2005
module auth_encrypt_fsm #(parameter DATA_WIDTH = 16) (
    input wire clk, rst_l,
    input wire start, data_valid,
    input wire [DATA_WIDTH-1:0] data_in, key, nonce,
    output reg [DATA_WIDTH-1:0] data_out,
    output reg busy, done, auth_ok
);
    // State encoding using one-hot encoding for better synthesis
    localparam IDLE     = 6'b000001;
    localparam INIT     = 6'b000010;
    localparam PROCESS  = 6'b000100;
    localparam FINALIZE = 6'b001000;
    localparam VERIFY   = 6'b010000;
    localparam COMPLETE = 6'b100000;
    
    reg [5:0] state, next_state;
    reg [DATA_WIDTH-1:0] running_auth;
    
    // Registered outputs to improve timing
    reg busy_r, done_r, auth_ok_r;
    reg [DATA_WIDTH-1:0] data_out_r;
    
    // State register
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) 
            state <= IDLE;
        else 
            state <= next_state;
    end
    
    // Next state logic - optimized comparison structure
    always @(*) begin
        case (1'b1) // Parallel case statement optimized for one-hot encoding
            state[0]: next_state = start ? INIT : IDLE;
            state[1]: next_state = PROCESS;
            state[2]: next_state = data_valid ? PROCESS : FINALIZE;
            state[3]: next_state = VERIFY;
            state[4]: next_state = COMPLETE;
            state[5]: next_state = IDLE;
            default:  next_state = IDLE;
        endcase
    end
    
    // Datapath logic
    always @(posedge clk or negedge rst_l) begin
        if (!rst_l) begin
            busy_r <= 1'b0;
            done_r <= 1'b0;
            auth_ok_r <= 1'b0;
            running_auth <= {DATA_WIDTH{1'b0}};
            data_out_r <= {DATA_WIDTH{1'b0}};
        end else begin
            case (1'b1) // Parallel case optimized for one-hot state encoding
                next_state[0]: begin // IDLE
                    busy_r <= start;
                    done_r <= 1'b0;
                end
                
                next_state[1]: begin // INIT
                    running_auth <= nonce ^ key;
                end
                
                next_state[2]: begin // PROCESS
                    if (data_valid) begin
                        data_out_r <= data_in ^ key;
                        running_auth <= running_auth ^ data_in;
                    end
                end
                
                next_state[3]: begin // FINALIZE
                    // Prepare for verification
                end
                
                next_state[4]: begin // VERIFY
                    auth_ok_r <= (running_auth == data_in);
                end
                
                next_state[5]: begin // COMPLETE
                    busy_r <= 1'b0;
                    done_r <= 1'b1;
                end
            endcase
        end
    end
    
    // Output assignments
    always @(*) begin
        busy = busy_r;
        done = done_r;
        auth_ok = auth_ok_r;
        data_out = data_out_r;
    end
    
endmodule