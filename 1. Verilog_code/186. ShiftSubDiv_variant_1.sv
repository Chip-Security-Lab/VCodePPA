//SystemVerilog
module ShiftSubDiv(
    input clk,
    input rst_n,
    input [7:0] dividend, divisor,
    input valid_in,           // Sender indicates data is valid
    output ready_out,         // Receiver indicates it's ready to accept data
    output reg [7:0] quotient,
    output reg [7:0] remainder,
    output reg valid_out,     // Receiver indicates result is valid
    input ready_in            // Sender indicates it's ready to accept result
);
    // Internal signals
    reg [15:0] rem;
    reg [3:0] count;
    reg busy;
    reg [7:0] divisor_reg;
    reg [7:0] quot_temp;
    
    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam RESULT = 2'b10;
    reg [1:0] state, next_state;
    
    // Ready to accept new data when idle or when finishing a transaction
    assign ready_out = (state == IDLE) || (state == RESULT && ready_in && valid_out);
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state;
    end
    
    // Next state logic
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: 
                if (valid_in && ready_out)
                    next_state = COMPUTE;
            
            COMPUTE:
                if (count == 4'd8)
                    next_state = RESULT;
            
            RESULT:
                if (valid_out && ready_in)
                    next_state = IDLE;
        endcase
    end
    
    // Datapath - Division operation
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            rem <= 16'b0;
            count <= 4'd0;
            busy <= 1'b0;
            divisor_reg <= 8'b0;
            quot_temp <= 8'b0;
            quotient <= 8'b0;
            remainder <= 8'b0;
            valid_out <= 1'b0;
        end
        else begin
            case (state)
                IDLE: begin
                    valid_out <= 1'b0;
                    if (valid_in && ready_out) begin
                        rem <= {8'b0, dividend};
                        divisor_reg <= divisor;
                        count <= 4'd0;
                        quot_temp <= 8'b0;
                    end
                end
                
                COMPUTE: begin
                    // Perform one iteration of the division algorithm
                    rem <= rem << 1;
                    if (rem[15:8] >= divisor_reg && divisor_reg != 0) begin
                        rem[15:8] <= rem[15:8] - divisor_reg;
                        quot_temp[7-count] <= 1'b1;
                    end
                    count <= count + 1'b1;
                end
                
                RESULT: begin
                    if (!valid_out) begin
                        quotient <= quot_temp;
                        remainder <= rem[15:8];
                        valid_out <= 1'b1;
                    end
                    else if (ready_in) begin
                        valid_out <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule