//SystemVerilog
module ext_clk_precision_timer #(
    parameter WIDTH = 20
)(
    input  wire             ext_clk,
    input  wire             sys_clk,
    input  wire             rst_n,
    input  wire             start,
    input  wire             stop,
    output reg              busy,
    output reg  [WIDTH-1:0] elapsed_time
);
    // Control path signals - system clock domain
    reg [1:0]       start_sync_pipe;
    reg [1:0]       stop_sync_pipe;
    wire            start_pulse;
    wire            stop_pulse;
    reg             start_cmd;
    reg             stop_cmd;
    
    // Data path signals - external clock domain
    reg             running_state;
    reg [WIDTH-1:0] counter_reg;
    reg             capture_flag;
    reg [WIDTH-1:0] time_capture;
    
    // Cross-domain synchronization stage - system clock domain
    always @(posedge sys_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_sync_pipe <= 2'b00;
            stop_sync_pipe <= 2'b00;
            start_cmd <= 1'b0;
            stop_cmd <= 1'b0;
        end else begin
            // Two-stage synchronizer pipeline
            start_sync_pipe <= {start_sync_pipe[0], start};
            stop_sync_pipe <= {stop_sync_pipe[0], stop};
            
            // Edge detection and command generation
            start_cmd <= start_pulse;
            stop_cmd <= stop_pulse;
        end
    end
    
    // Edge detection logic - generates single-cycle pulses
    assign start_pulse = (start_sync_pipe[1:0] == 2'b01);
    assign stop_pulse = (stop_sync_pipe[1:0] == 2'b01);
    
    // Command synchronization to external clock domain
    reg [1:0] start_ext_sync;
    reg [1:0] stop_ext_sync;
    wire      start_ext_pulse;
    wire      stop_ext_pulse;
    
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            start_ext_sync <= 2'b00;
            stop_ext_sync <= 2'b00;
        end else begin
            start_ext_sync <= {start_ext_sync[0], start_cmd};
            stop_ext_sync <= {stop_ext_sync[0], stop_cmd};
        end
    end
    
    // External clock domain edge detection
    assign start_ext_pulse = (start_ext_sync[1:0] == 2'b01);
    assign stop_ext_pulse = (stop_ext_sync[1:0] == 2'b01);
    
    // Timer control FSM - external clock domain
    localparam IDLE = 2'b00;
    localparam COUNTING = 2'b01;
    localparam CAPTURE = 2'b10;
    
    reg [1:0] timer_state;
    reg [1:0] timer_next_state;
    
    // Timer state machine - sequential logic
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            timer_state <= IDLE;
        end else begin
            timer_state <= timer_next_state;
        end
    end
    
    // Timer state machine - combinational next state logic
    always @(*) begin
        timer_next_state = timer_state;
        
        case (timer_state)
            IDLE: begin
                if (start_ext_pulse)
                    timer_next_state = COUNTING;
            end
            
            COUNTING: begin
                if (stop_ext_pulse)
                    timer_next_state = CAPTURE;
            end
            
            CAPTURE: begin
                timer_next_state = IDLE;
            end
            
            default: timer_next_state = IDLE;
        endcase
    end
    
    // Data path - counter operation and time capture
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_reg <= {WIDTH{1'b0}};
            running_state <= 1'b0;
            capture_flag <= 1'b0;
            time_capture <= {WIDTH{1'b0}};
        end else begin
            // Default states
            capture_flag <= 1'b0;
            
            case (timer_state)
                IDLE: begin
                    running_state <= 1'b0;
                    if (start_ext_pulse) begin
                        counter_reg <= {WIDTH{1'b0}};
                        running_state <= 1'b1;
                    end
                end
                
                COUNTING: begin
                    running_state <= 1'b1;
                    counter_reg <= counter_reg + 1'b1;
                    
                    if (stop_ext_pulse) begin
                        capture_flag <= 1'b1;
                        time_capture <= counter_reg;
                    end
                end
                
                CAPTURE: begin
                    running_state <= 1'b0;
                end
                
                default: begin
                    running_state <= 1'b0;
                end
            endcase
        end
    end
    
    // Output stage - register outputs for better timing
    always @(posedge ext_clk or negedge rst_n) begin
        if (!rst_n) begin
            busy <= 1'b0;
            elapsed_time <= {WIDTH{1'b0}};
        end else begin
            busy <= running_state;
            
            if (capture_flag) begin
                elapsed_time <= time_capture;
            end
        end
    end
    
endmodule