//SystemVerilog
// Top-level module
module usb_low_power_ctrl (
    input  wire       clk_48mhz,
    input  wire       reset_n,
    input  wire       bus_activity,
    input  wire       suspend_req,
    input  wire       resume_req,
    output wire       suspend_state,
    output wire       clk_en,
    output wire       pll_en
);

    // State definitions
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    
    // Internal signals
    wire [1:0]  current_state;
    wire [15:0] idle_count;
    wire        bus_activity_sync;
    wire        suspend_req_sync;
    wire        resume_req_sync;

    // Input synchronization submodule
    input_synchronizer u_input_sync (
        .clk_48mhz      (clk_48mhz),
        .reset_n        (reset_n),
        .bus_activity   (bus_activity),
        .suspend_req    (suspend_req),
        .resume_req     (resume_req),
        .bus_activity_r (bus_activity_sync),
        .suspend_req_r  (suspend_req_sync),
        .resume_req_r   (resume_req_sync)
    );

    // State control logic submodule
    state_controller u_state_ctrl (
        .clk_48mhz      (clk_48mhz),
        .reset_n        (reset_n),
        .bus_activity_r (bus_activity_sync),
        .suspend_req_r  (suspend_req_sync),
        .resume_req_r   (resume_req_sync),
        .state          (current_state),
        .idle_counter   (idle_count)
    );

    // Output generator submodule
    output_generator u_output_gen (
        .clk_48mhz      (clk_48mhz),
        .reset_n        (reset_n),
        .state          (current_state),
        .idle_counter   (idle_count),
        .bus_activity_r (bus_activity_sync),
        .suspend_req_r  (suspend_req_sync),
        .resume_req_r   (resume_req_sync),
        .suspend_state  (suspend_state),
        .clk_en         (clk_en),
        .pll_en         (pll_en)
    );

endmodule

// Input synchronizer module - handles input signal registration
module input_synchronizer (
    input  wire       clk_48mhz,
    input  wire       reset_n,
    input  wire       bus_activity,
    input  wire       suspend_req,
    input  wire       resume_req,
    output reg        bus_activity_r,
    output reg        suspend_req_r,
    output reg        resume_req_r
);

    // Double register inputs to reduce metastability
    reg bus_activity_meta, suspend_req_meta, resume_req_meta;
    
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            // Reset metastability registers
            bus_activity_meta <= 1'b0;
            suspend_req_meta  <= 1'b0;
            resume_req_meta   <= 1'b0;
            
            // Reset output registers
            bus_activity_r    <= 1'b0;
            suspend_req_r     <= 1'b0;
            resume_req_r      <= 1'b0;
        end else begin
            // First stage synchronization
            bus_activity_meta <= bus_activity;
            suspend_req_meta  <= suspend_req;
            resume_req_meta   <= resume_req;
            
            // Second stage synchronization
            bus_activity_r    <= bus_activity_meta;
            suspend_req_r     <= suspend_req_meta;
            resume_req_r      <= resume_req_meta;
        end
    end

endmodule

// State controller module - handles state transitions and counter
module state_controller (
    input  wire       clk_48mhz,
    input  wire       reset_n,
    input  wire       bus_activity_r,
    input  wire       suspend_req_r,
    input  wire       resume_req_r,
    output reg  [1:0] state,
    output reg  [15:0] idle_counter
);

    // State definitions
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    
    // Internal signals
    reg [1:0]  next_state;
    reg [15:0] next_idle_counter;
    
    // Combinational logic for next state and counter
    always @(*) begin
        // Default assignments
        next_state = state;
        next_idle_counter = idle_counter;
        
        case (state)
            ACTIVE: begin
                if (bus_activity_r)
                    next_idle_counter = 16'd0;
                else begin
                    next_idle_counter = idle_counter + 1'b1;
                    if (idle_counter > 16'd3000 || suspend_req_r)
                        next_state = IDLE;
                end
            end
            
            IDLE: begin
                if (bus_activity_r) begin
                    next_state = ACTIVE;
                    next_idle_counter = 16'd0;
                end else if (idle_counter > 16'd20000) begin
                    next_state = SUSPEND;
                end else
                    next_idle_counter = idle_counter + 1'b1;
            end
            
            SUSPEND: begin
                if (bus_activity_r || resume_req_r) begin
                    next_state = RESUME;
                end
            end
            
            RESUME: begin
                if (idle_counter < 16'd1000)
                    next_idle_counter = idle_counter + 1'b1;
                else begin
                    next_state = ACTIVE;
                    next_idle_counter = 16'd0;
                end
            end
        endcase
    end
    
    // Sequential logic for state and counter updates
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            state <= ACTIVE;
            idle_counter <= 16'd0;
        end else begin
            state <= next_state;
            idle_counter <= next_idle_counter;
        end
    end

endmodule

// Output generator module - manages output signals based on state
module output_generator (
    input  wire       clk_48mhz,
    input  wire       reset_n,
    input  wire [1:0] state,
    input  wire [15:0] idle_counter,
    input  wire       bus_activity_r,
    input  wire       suspend_req_r,
    input  wire       resume_req_r,
    output reg        suspend_state,
    output reg        clk_en,
    output reg        pll_en
);

    // State definitions
    localparam ACTIVE = 2'b00, IDLE = 2'b01, SUSPEND = 2'b10, RESUME = 2'b11;
    
    // Internal signals
    reg next_suspend_state, next_clk_en, next_pll_en;
    
    // Combinational logic for outputs
    always @(*) begin
        // Default assignments
        next_suspend_state = suspend_state;
        next_clk_en = clk_en;
        next_pll_en = pll_en;
        
        case (state)
            ACTIVE: begin
                next_clk_en = 1'b1;
                next_pll_en = 1'b1;
            end
            
            IDLE: begin
                if (idle_counter > 16'd20000) begin
                    next_suspend_state = 1'b1;
                    next_clk_en = 1'b0;
                    next_pll_en = 1'b0;
                end
            end
            
            SUSPEND: begin
                if (bus_activity_r || resume_req_r) begin
                    next_pll_en = 1'b1;
                end
            end
            
            RESUME: begin
                if (idle_counter >= 16'd1000) begin
                    next_clk_en = 1'b1;
                    next_suspend_state = 1'b0;
                end
            end
        endcase
    end
    
    // Sequential logic for output registers
    always @(posedge clk_48mhz or negedge reset_n) begin
        if (!reset_n) begin
            suspend_state <= 1'b0;
            clk_en <= 1'b1;
            pll_en <= 1'b1;
        end else begin
            suspend_state <= next_suspend_state;
            clk_en <= next_clk_en;
            pll_en <= next_pll_en;
        end
    end

endmodule