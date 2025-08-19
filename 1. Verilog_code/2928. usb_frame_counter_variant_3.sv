//SystemVerilog
module usb_frame_counter(
    input wire clk,
    input wire rst_n,
    input wire sof_received,
    input wire frame_error,
    input wire [10:0] frame_number,
    output wire [10:0] expected_frame,
    output wire frame_missed,
    output wire frame_mismatch,
    output wire [15:0] sof_count,
    output wire [15:0] error_count,
    output wire [1:0] counter_status
);
    // Internal signals
    wire [15:0] consecutive_good;
    wire initialized;

    // Frame tracking module
    frame_tracker u_frame_tracker (
        .clk(clk),
        .rst_n(rst_n),
        .sof_received(sof_received),
        .frame_number(frame_number),
        .expected_frame(expected_frame),
        .frame_mismatch(frame_mismatch),
        .initialized(initialized),
        .consecutive_good(consecutive_good)
    );

    // Counter module
    error_counter u_error_counter (
        .clk(clk),
        .rst_n(rst_n),
        .sof_received(sof_received),
        .frame_error(frame_error),
        .frame_mismatch(frame_mismatch),
        .sof_count(sof_count),
        .error_count(error_count),
        .frame_missed(frame_missed)
    );

    // Status monitor module
    status_monitor u_status_monitor (
        .clk(clk),
        .rst_n(rst_n),
        .error_count(error_count),
        .counter_status(counter_status)
    );
endmodule

// Frame tracking logic
module frame_tracker (
    input wire clk,
    input wire rst_n,
    input wire sof_received,
    input wire [10:0] frame_number,
    output reg [10:0] expected_frame,
    output reg frame_mismatch,
    output reg initialized,
    output reg [15:0] consecutive_good
);
    // Forward registers for combinational path optimization
    reg sof_received_r;
    reg [10:0] frame_number_r;
    reg [10:0] next_expected_frame;
    reg next_frame_mismatch;
    reg next_initialized;
    reg [15:0] next_consecutive_good;
    
    // Input registers stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sof_received_r <= 1'b0;
            frame_number_r <= 11'd0;
        end else begin
            sof_received_r <= sof_received;
            frame_number_r <= frame_number;
        end
    end
    
    // Combinational logic moved before registers
    always @(*) begin
        // Default assignments
        next_frame_mismatch = 1'b0;
        next_expected_frame = expected_frame;
        next_initialized = initialized;
        next_consecutive_good = consecutive_good;
        
        if (sof_received_r) begin
            if (!initialized) begin
                // First SOF received - initialize expected counter
                next_expected_frame = frame_number_r;
                next_initialized = 1'b1;
                next_consecutive_good = 16'd1;
            end else begin
                // Check if received frame matches expected
                if (frame_number_r != expected_frame) begin
                    next_frame_mismatch = 1'b1;
                    next_consecutive_good = 16'd0;
                end else begin
                    next_consecutive_good = consecutive_good + 16'd1;
                end
                
                // Update expected frame for next SOF
                next_expected_frame = (frame_number_r + 11'd1) & 11'h7FF;
            end
        end
    end
    
    // Output registers stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            expected_frame <= 11'd0;
            frame_mismatch <= 1'b0;
            initialized <= 1'b0;
            consecutive_good <= 16'd0;
        end else begin
            expected_frame <= next_expected_frame;
            frame_mismatch <= next_frame_mismatch;
            initialized <= next_initialized;
            consecutive_good <= next_consecutive_good;
        end
    end
endmodule

// Error and SOF counter logic
module error_counter (
    input wire clk,
    input wire rst_n,
    input wire sof_received,
    input wire frame_error,
    input wire frame_mismatch,
    output reg [15:0] sof_count,
    output reg [15:0] error_count,
    output reg frame_missed
);
    // Forward registers for combinational path optimization
    reg sof_received_r, frame_error_r, frame_mismatch_r;
    reg [15:0] next_sof_count;
    reg [15:0] next_error_count;
    reg next_frame_missed;
    
    // Input registers stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sof_received_r <= 1'b0;
            frame_error_r <= 1'b0;
            frame_mismatch_r <= 1'b0;
        end else begin
            sof_received_r <= sof_received;
            frame_error_r <= frame_error;
            frame_mismatch_r <= frame_mismatch;
        end
    end
    
    // Combinational logic moved before registers
    always @(*) begin
        // Default assignments
        next_sof_count = sof_count;
        next_error_count = error_count;
        next_frame_missed = 1'b0;
        
        if (sof_received_r) begin
            next_sof_count = sof_count + 16'd1;
            
            if (frame_mismatch_r) begin
                next_error_count = error_count + 16'd1;
            end
        end else if (frame_error_r) begin
            next_error_count = error_count + 16'd1;
            next_frame_missed = 1'b1;
        end
    end
    
    // Output registers stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            sof_count <= 16'd0;
            error_count <= 16'd0;
            frame_missed <= 1'b0;
        end else begin
            sof_count <= next_sof_count;
            error_count <= next_error_count;
            frame_missed <= next_frame_missed;
        end
    end
endmodule

// Status monitor logic
module status_monitor (
    input wire clk,
    input wire rst_n,
    input wire [15:0] error_count,
    output reg [1:0] counter_status
);
    reg [15:0] error_count_r;
    reg [1:0] next_counter_status;
    
    // Input register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            error_count_r <= 16'd0;
        end else begin
            error_count_r <= error_count;
        end
    end
    
    // Combinational logic moved before registers
    always @(*) begin
        if (error_count_r > 16'd10)
            next_counter_status = 2'b11;     // Critical errors
        else if (error_count_r > 16'd0)
            next_counter_status = 2'b01;     // Warning
        else
            next_counter_status = 2'b00;     // Good
    end
    
    // Output register stage
    always @(posedge clk or negedge rst_n) begin
        if (!rst_n) begin
            counter_status <= 2'b00;
        end else begin
            counter_status <= next_counter_status;
        end
    end
endmodule