//SystemVerilog
module decoder_crossbar #(MASTERS=2, SLAVES=4) (
    input clk,
    input rst_n,
    input [MASTERS-1:0] master_req,
    input [MASTERS-1:0][7:0] addr,
    output reg [MASTERS-1:0][SLAVES-1:0] slave_sel
);

// State encoding
localparam IDLE = 2'b00;
localparam PROCESS = 2'b01;
localparam DONE = 2'b10;

// State and control registers
reg [1:0] current_state, next_state;
reg [7:0] master_index;
reg [MASTERS-1:0][SLAVES-1:0] slave_sel_next;

// State machine
always @(posedge clk or negedge rst_n) begin
    if (!rst_n) begin
        current_state <= IDLE;
        master_index <= 0;
        slave_sel <= 0;
    end else begin
        current_state <= next_state;
        slave_sel <= slave_sel_next;
    end
end

// Next state logic
always @* begin
    next_state = current_state;
    
    case (current_state)
        IDLE: begin
            next_state = PROCESS;
        end
        
        PROCESS: begin
            if (master_index < MASTERS-1) begin
                next_state = PROCESS;
            end else begin
                next_state = DONE;
            end
        end
        
        DONE: begin
            next_state = IDLE;
        end
        
        default: begin
            next_state = IDLE;
        end
    endcase
end

// Output logic
always @* begin
    slave_sel_next = slave_sel;
    
    case (current_state)
        IDLE: begin
            master_index = 0;
        end
        
        PROCESS: begin
            slave_sel_next[master_index] = master_req[master_index] ? 
                (1 << (addr[master_index] % SLAVES)) : {SLAVES{1'b0}};
            master_index = master_index + 1;
        end
        
        DONE: begin
            // No changes to slave_sel in DONE state
        end
        
        default: begin
            // No changes in default state
        end
    endcase
end

endmodule