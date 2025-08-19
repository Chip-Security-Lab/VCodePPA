//SystemVerilog
// SystemVerilog
module elias_gamma (
    input            clk,
    input            rst_n,
    input     [15:0] value,
    input            valid_in,
    output           ready_out,
    output    [31:0] code,
    output    [5:0]  length,
    output           valid_out,
    input            ready_in
);
    reg [31:0] code_r;
    reg [5:0]  length_r;
    reg        valid_out_r;
    reg        ready_out_r;
    
    reg [4:0]  N;
    reg [15:0] val_masked;
    
    // Buffered high fanout signals
    reg [31:0] code_r_buf1, code_r_buf2;
    reg [4:0]  N_buf1, N_buf2;
    reg [15:0] val_masked_buf1, val_masked_buf2;
    
    // FSM states
    localparam IDLE = 2'b00;
    localparam COMPUTE = 2'b01;
    localparam WAIT_ACK = 2'b10;
    
    // Buffered state signals
    reg [1:0] state, next_state;
    reg [1:0] next_state_buf1, next_state_buf2;
    reg [1:0] IDLE_buf1, IDLE_buf2, COMPUTE_buf, WAIT_ACK_buf;
    
    // Initialize buffered constants
    initial begin
        IDLE_buf1 = IDLE;
        IDLE_buf2 = IDLE;
        COMPUTE_buf = COMPUTE;
        WAIT_ACK_buf = WAIT_ACK;
    end
    
    // State register
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n)
            state <= IDLE_buf1;
        else
            state <= next_state;
    end
    
    // Buffer high fanout signals
    always @(posedge clk) begin
        // Buffer code_r for different parts of the circuit
        code_r_buf1 <= code_r;
        code_r_buf2 <= code_r;
        
        // Buffer N for different parts of the circuit
        N_buf1 <= N;
        N_buf2 <= N;
        
        // Buffer val_masked for different parts of the circuit
        val_masked_buf1 <= val_masked;
        val_masked_buf2 <= val_masked;
        
        // Buffer next_state for different parts of the circuit
        next_state_buf1 <= next_state;
        next_state_buf2 <= next_state;
    end
    
    // Next state logic with balanced load
    always @(*) begin
        next_state = state;
        case (state)
            IDLE_buf1: begin
                if (valid_in && ready_out_r)
                    next_state = COMPUTE_buf;
            end
            COMPUTE_buf: begin
                next_state = WAIT_ACK_buf;
            end
            WAIT_ACK_buf: begin
                if (ready_in && valid_out_r)
                    next_state = IDLE_buf2;
            end
            default: next_state = IDLE_buf2;
        endcase
    end
    
    // Output logic with buffered high fanout signals
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            code_r <= 32'b0;
            length_r <= 6'b0;
            valid_out_r <= 1'b0;
            ready_out_r <= 1'b1;
        end else begin
            case (state)
                IDLE_buf1: begin
                    valid_out_r <= 1'b0;
                    ready_out_r <= 1'b1;
                    if (valid_in && ready_out_r) begin
                        ready_out_r <= 1'b0;
                    end
                end
                COMPUTE_buf: begin
                    // Find position of MSB using priority encoding
                    N = 0;
                    val_masked = value;
                    
                    // Split the computation into balanced stages
                    if (val_masked[15:8] != 0) begin 
                        N = N + 8; 
                        val_masked = val_masked[15:8]; 
                    end else begin
                        val_masked = val_masked[7:0];
                    end
                    
                    if (val_masked[7:4] != 0) begin 
                        N = N + 4; 
                        val_masked = val_masked[7:4]; 
                    end else begin
                        val_masked = val_masked[3:0];
                    end
                    
                    if (val_masked[3:2] != 0) begin 
                        N = N + 2; 
                        val_masked = val_masked[3:2]; 
                    end else begin
                        val_masked = val_masked[1:0];
                    end
                    
                    if (val_masked[1] != 0) begin 
                        N = N + 1; 
                    end
                    
                    // Add 1 for final position (N is now bit position, 0-based)
                    N = N + 1;
                    
                    // Generate code with buffered signals
                    code_r = 0;
                    
                    // Use buffered signals to balance the load
                    // Split the loop into two parts to reduce critical path
                    for (integer i = 0; i < 16; i = i + 1) begin
                        if (i < N_buf1-1)
                            code_r[31-i] = 1'b0;
                        else if (i == N_buf1-1)
                            code_r[31-i] = 1'b1;
                        else if (i < 2*N_buf1-1)
                            code_r[31-i] = value[N_buf1-1-(i-N_buf1)];
                    end
                    
                    for (integer i = 16; i < 32; i = i + 1) begin
                        if (i < N_buf2-1)
                            code_r[31-i] = 1'b0;
                        else if (i == N_buf2-1)
                            code_r[31-i] = 1'b1;
                        else if (i < 2*N_buf2-1)
                            code_r[31-i] = value[N_buf2-1-(i-N_buf2)];
                    end
                    
                    length_r = 2*N_buf1 - 1;
                    valid_out_r <= 1'b1;
                end
                WAIT_ACK_buf: begin
                    if (ready_in && valid_out_r) begin
                        valid_out_r <= 1'b0;
                        ready_out_r <= 1'b1;
                    end
                end
            endcase
        end
    end
    
    // Output assignments with buffered signals
    reg [31:0] output_code_buf;
    reg [5:0]  output_length_buf;
    
    always @(posedge clk) begin
        output_code_buf <= code_r_buf1;
        output_length_buf <= length_r;
    end
    
    assign code = output_code_buf;
    assign length = output_length_buf;
    assign valid_out = valid_out_r;
    assign ready_out = ready_out_r;
    
endmodule