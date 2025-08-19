//SystemVerilog
module async_pipe_mult (
    input  wire        clk,
    input  wire        rst_n,
    input  wire [7:0]  in1, in2,
    output wire [15:0] out,
    input  wire        req,
    output reg         ack
);

    // State definitions
    localparam IDLE     = 2'b00;
    localparam COMPUTING = 2'b01;
    localparam COMPLETED = 2'b10;
    
    // Internal signals with clear naming for data flow stages
    reg [1:0]  state_r, state_next;
    reg [7:0]  in1_r, in2_r;
    reg [15:0] mult_result_r;
    reg        ack_r;
    
    // Pipeline registers for improved timing
    reg [7:0]  in1_pipe_r, in2_pipe_r;
    reg [15:0] out_pipe_r;
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state_r <= IDLE;
            ack_r <= 1'b0;
        end else begin
            state_r <= state_next;
            ack_r <= (state_next == COMPLETED);
        end
    end
    
    // Combinational state and data path logic
    always @(*) begin
        // Default assignments
        state_next = state_r;
        in1_pipe_r = in1_r;
        in2_pipe_r = in2_r;
        
        case (state_r)
            IDLE: begin
                if (req && !ack_r) begin
                    state_next = COMPUTING;
                    in1_pipe_r = in1;
                    in2_pipe_r = in2;
                end
            end
            
            COMPUTING: begin
                state_next = COMPLETED;
                mult_result_r = in1_pipe_r * in2_pipe_r;
            end
            
            COMPLETED: begin
                if (!req) begin
                    state_next = IDLE;
                end
            end
            
            default: state_next = IDLE;
        endcase
    end
    
    // Input registers
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            in1_r <= 8'h0;
            in2_r <= 8'h0;
        end else if (state_r == IDLE && req && !ack_r) begin
            in1_r <= in1;
            in2_r <= in2;
        end
    end
    
    // Output pipeline register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            out_pipe_r <= 16'h0;
        end else if (state_r == COMPLETED) begin
            out_pipe_r <= mult_result_r;
        end
    end
    
    // Output assignments
    assign out = out_pipe_r;
    assign ack = ack_r;
    
endmodule