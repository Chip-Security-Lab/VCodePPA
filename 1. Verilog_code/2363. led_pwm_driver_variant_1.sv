//SystemVerilog
// Top module - LED PWM Driver with hierarchical design
module led_pwm_driver #(parameter W=8)(
    input  logic clk, 
    input  logic [W-1:0] duty,
    output logic pwm_out
);
    // Internal signals for connecting submodules
    logic [W-1:0] cnt;
    logic [W-1:0] duty_reg;
    
    // Instantiate counter module
    counter_module #(.WIDTH(W)) counter_inst (
        .clk(clk),
        .cnt_out(cnt)
    );
    
    // Instantiate duty cycle buffer module
    duty_buffer #(.WIDTH(W)) duty_buff_inst (
        .clk(clk),
        .duty_in(duty),
        .duty_out(duty_reg)
    );
    
    // Instantiate PWM comparator module
    pwm_comparator #(.WIDTH(W)) pwm_comp_inst (
        .clk(clk),
        .cnt_in(cnt),
        .duty_in(duty_reg),
        .pwm_out(pwm_out)
    );
endmodule

// Counter module - generates counter value
module counter_module #(parameter WIDTH=8)(
    input  logic clk,
    output logic [WIDTH-1:0] cnt_out
);
    logic [WIDTH-1:0] cnt;
    
    // Counter logic
    wire [WIDTH-1:0] cnt_next = cnt + 1'b1;
    
    always_ff @(posedge clk) begin
        // Update counter
        cnt <= cnt_next;
    end
    
    assign cnt_out = cnt;
endmodule

// Duty cycle buffer module - registers the duty cycle input
module duty_buffer #(parameter WIDTH=8)(
    input  logic clk,
    input  logic [WIDTH-1:0] duty_in,
    output logic [WIDTH-1:0] duty_out
);
    always_ff @(posedge clk) begin
        // Register duty input to break timing path
        duty_out <= duty_in;
    end
endmodule

// PWM comparator module - compares counter with duty cycle
module pwm_comparator #(parameter WIDTH=8)(
    input  logic clk,
    input  logic [WIDTH-1:0] cnt_in,
    input  logic [WIDTH-1:0] duty_in,
    output logic pwm_out
);
    logic pwm_cmp_reg;
    
    always_ff @(posedge clk) begin
        // Register comparison result after computation
        pwm_cmp_reg <= (cnt_in < duty_in);
    end
    
    assign pwm_out = pwm_cmp_reg;
endmodule