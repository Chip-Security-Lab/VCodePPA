//SystemVerilog
//IEEE 1364-2005 Verilog
module blowfish_pgen (
    input wire clk,
    input wire rst_n,
    
    // Request-Acknowledge Interface Inputs
    input wire req_in,
    input wire [31:0] key_segment,
    
    // Request-Acknowledge Interface Outputs
    output reg req_out,
    output reg [31:0] p_box_out,
    
    // Acknowledge signals
    input wire ack_out,
    output reg ack_in
);
    reg [31:0] p_box [0:17];
    integer i;
    
    // State machine states
    localparam IDLE = 2'b00;
    localparam INIT = 2'b01;
    localparam PROCESS = 2'b10;
    localparam OUTPUT = 2'b11;
    
    reg [1:0] state, next_state;
    reg init_done;
    reg process_done;
    
    // Buffer registers for high fanout signals
    reg [1:0] next_state_buf1, next_state_buf2;
    reg [31:0] p_box_buf1 [0:8];
    reg [31:0] p_box_buf2 [0:8];
    reg b0_buf1, b0_buf2, b0_buf3;
    reg b1_buf1, b1_buf2;
    
    // State machine with buffered next_state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE;
        else
            state <= next_state_buf2;
    end
    
    // Next state logic with buffer for high fanout signal next_state
    always @(*) begin
        next_state = state;
        
        case (state)
            IDLE: begin
                if (req_in)
                    next_state = INIT;
            end
            
            INIT: begin
                if (init_done)
                    next_state = PROCESS;
            end
            
            PROCESS: begin
                if (process_done)
                    next_state = OUTPUT;
            end
            
            OUTPUT: begin
                if (ack_out && req_out)
                    next_state = IDLE;
            end
        endcase
    end
    
    // Buffer registers for next_state
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            next_state_buf1 <= IDLE;
            next_state_buf2 <= IDLE;
        end else begin
            next_state_buf1 <= next_state;
            next_state_buf2 <= next_state_buf1;
        end
    end
    
    // Buffering for p_box signals - split to reduce fanout
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            for(i=0; i<=8; i=i+1) begin
                p_box_buf1[i] <= 32'h0;
                p_box_buf2[i] <= 32'h0;
            end
        end else begin
            for(i=0; i<=8; i=i+1) begin
                p_box_buf1[i] <= p_box[i];
                p_box_buf2[i] <= p_box[i+9];
            end
        end
    end
    
    // Buffer signals for high fanout control flags
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            b0_buf1 <= 1'b0;
            b0_buf2 <= 1'b0;
            b0_buf3 <= 1'b0;
            b1_buf1 <= 1'b0;
            b1_buf2 <= 1'b0;
        end else begin
            b0_buf1 <= init_done;
            b0_buf2 <= b0_buf1;
            b0_buf3 <= b0_buf2;
            b1_buf1 <= process_done;
            b1_buf2 <= b1_buf1;
        end
    end
    
    // Control signals and data processing
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            init_done <= 1'b0;
            process_done <= 1'b0;
            req_out <= 1'b0;
            ack_in <= 1'b0;
            p_box_out <= 32'h0;
            
            for(i=0; i<18; i=i+1)
                p_box[i] <= 32'h0;
        end else begin
            case (state)
                IDLE: begin
                    init_done <= 1'b0;
                    process_done <= 1'b0;
                    req_out <= 1'b0;
                    if (req_in)
                        ack_in <= 1'b1;
                    else
                        ack_in <= 1'b0;
                end
                
                INIT: begin
                    ack_in <= 1'b0;
                    // Initialize p_box in balanced groups to reduce fanout
                    for(i=0; i<9; i=i+1)
                        p_box[i] <= 32'hB7E15163 + i*32'h9E3779B9;
                    for(i=9; i<18; i=i+1)
                        p_box[i] <= 32'hB7E15163 + i*32'h9E3779B9;
                    init_done <= 1'b1;
                end
                
                PROCESS: begin
                    p_box[0] <= p_box[0] ^ key_segment;
                    // Process p_box in balanced groups
                    for(i=1; i<9; i=i+1)
                        p_box[i] <= p_box[i] + (p_box_buf1[i-1] << 3);
                    for(i=9; i<18; i=i+1)
                        p_box[i] <= p_box[i] + (p_box_buf1[i-9] << 3);
                    p_box_out <= p_box_buf2[8]; // Use buffered value for output
                    process_done <= 1'b1;
                end
                
                OUTPUT: begin
                    req_out <= 1'b1;
                    if (ack_out && req_out) begin
                        req_out <= 1'b0;
                        ack_in <= 1'b0;
                    end
                end
            endcase
        end
    end
endmodule