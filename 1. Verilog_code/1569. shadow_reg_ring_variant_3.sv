//SystemVerilog
module shadow_reg_ring #(parameter DW=8, DEPTH=4) (
    input clk,
    input rst_n,
    input shift,
    input [DW-1:0] new_data,
    input data_valid_in,
    output data_valid_out,
    output [DW-1:0] oldest_data
);
    // Pipeline stage registers for data
    reg [DW-1:0] pipe_data [0:DEPTH-1];
    // Pipeline valid flags
    reg [DEPTH-1:0] pipe_valid;
    // Pipeline control signals
    reg [1:0] state;
    
    // State definitions
    localparam IDLE = 2'b00;
    localparam ACTIVE = 2'b01;
    localparam FLUSH = 2'b10;
    
    integer i;
    
    // State transition logic
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            state <= IDLE;
        end else begin
            case (state)
                IDLE: begin
                    if (data_valid_in && shift) begin
                        state <= ACTIVE;
                    end
                end
                
                ACTIVE: begin
                    if (shift && !data_valid_in && (pipe_valid == {DEPTH{1'b0}})) begin
                        state <= IDLE;
                    end
                end
                
                default: state <= IDLE;
            endcase
        end
    end
    
    // Pipeline valid flags management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                pipe_valid[i] <= 1'b0;
            end
        end else if (shift) begin
            // Shift valid flags through pipeline stages
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                pipe_valid[i] <= pipe_valid[i-1];
            end
            
            // First stage valid flag update
            pipe_valid[0] <= (state == IDLE) ? (data_valid_in && shift) : 
                             (state == ACTIVE) ? data_valid_in : 1'b0;
        end
    end
    
    // Pipeline data management
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for (i = 0; i < DEPTH; i = i + 1) begin
                pipe_data[i] <= {DW{1'b0}};
            end
        end else if (shift) begin
            // Shift data through pipeline stages
            for (i = DEPTH-1; i > 0; i = i - 1) begin
                pipe_data[i] <= pipe_data[i-1];
            end
            
            // First stage data update
            if ((state == IDLE && data_valid_in) || 
                (state == ACTIVE && data_valid_in)) begin
                pipe_data[0] <= new_data;
            end else begin
                pipe_data[0] <= {DW{1'b0}};
            end
        end
    end
    
    // Output assignments
    assign oldest_data = pipe_data[DEPTH-1];
    assign data_valid_out = pipe_valid[DEPTH-1];
endmodule